<#
.SYNOPSIS
    Smoke-tests a built RE-Portable kit: checks the kit's layout, compiles lab\*.c with the kit's
    GCC, runs each practice program with right and wrong answers, and checks that Ghidra's
    portable paths follow the folder. With -Headless it also imports ex1 with Ghidra's
    analyzeHeadless and checks that Ghidra kept its settings inside the kit.

    Works on a local Windows machine as well as in CI. Every failure is reported (as a GitHub
    Actions error annotation when running in Actions) and the script exits 1 if anything failed.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tests\Test-Kit.ps1 -Kit .\RE-Portable
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Kit,
    [string]$LabSource = (Join-Path $PSScriptRoot '..\lab'),
    [string]$OutDir = '',
    [switch]$Headless               # also import ex1 with Ghidra's analyzeHeadless (slower)
)

$ErrorActionPreference = 'Stop'
$Kit       = (Resolve-Path -LiteralPath $Kit).Path.TrimEnd('\')
$LabSource = (Resolve-Path -LiteralPath $LabSource).Path
if (-not $OutDir) { $OutDir = Join-Path ([IO.Path]::GetTempPath()) ('lab-bin-' + [IO.Path]::GetRandomFileName()) }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory $OutDir | Out-Null }

$script:Failures = 0

function Write-Result {
    param([bool]$Ok, [string]$Name, [string]$Detail = '')
    if ($Ok) {
        Write-Host "  PASS  $Name" -ForegroundColor Green
    } else {
        $script:Failures++
        Write-Host "  FAIL  $Name  $Detail" -ForegroundColor Red
        if ($env:GITHUB_ACTIONS) {
            # Annotations show up on the check run, so failures are readable without the full log.
            $msg = ("$Name $Detail" -replace '%', '%25' -replace "`r", '' -replace "`n", '%0A')
            Write-Host "::error title=Test-Kit::$msg"
        }
    }
}

function Invoke-Program {
    # Runs $Exe with $InputLines on stdin. Returns @{ Code; Output }.
    param([string]$Exe, [string[]]$InputLines, [string[]]$Arguments = @(), [string]$WorkingDirectory = '')
    # Feed stdin from a file of raw ASCII bytes. Redirecting through Process.StandardInput on
    # Windows PowerShell 5.1 sends a UTF-8 BOM first, which corrupts the first line read.
    $base = Join-Path $OutDir ('run-' + [IO.Path]::GetRandomFileName())
    $in = "$base.in"; $stdout = "$base.out"; $stderr = "$base.err"
    [IO.File]::WriteAllBytes($in, [Text.Encoding]::ASCII.GetBytes((($InputLines -join "`n") + "`n")))
    $sp = @{ FilePath = $Exe; NoNewWindow = $true; PassThru = $true
             RedirectStandardInput = $in; RedirectStandardOutput = $stdout; RedirectStandardError = $stderr }
    if ($Arguments.Count -gt 0) { $sp.ArgumentList = $Arguments }
    if ($WorkingDirectory)      { $sp.WorkingDirectory = $WorkingDirectory }
    $p = Start-Process @sp
    $null = $p.Handle   # cache the handle so ExitCode is available after exit
    $done = $p.WaitForExit(15000)
    if (-not $done) { $p.Kill() }
    $p.WaitForExit()    # the untimed overload also waits until redirected output is fully written
    $out = ((Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw))
    if ($null -eq $out) { $out = '' }
    if (-not $done) { return @{ Code = -1; Output = "$out<timed out>" } }
    @{ Code = $p.ExitCode; Output = $out.Trim() }
}

function Test-Program {
    param([string]$Name, [string]$Exe, [string[]]$InputLines, [int]$ExpectCode, [string]$ExpectText)
    $r  = Invoke-Program $Exe $InputLines
    $ok = ($r.Code -eq $ExpectCode) -and ($r.Output -like "*$ExpectText*")
    Write-Result $ok $Name "(expected exit $ExpectCode and '$ExpectText'; got exit $($r.Code): $($r.Output))"
}

# --- kit layout ----------------------------------------------------------------
Write-Host "Kit layout ($Kit)"
foreach ($f in @('ghidra\ghidraRun.bat', 'ghidra\support\analyzeHeadless.bat', 'jdk\bin\java.exe',
                 'x64dbg\x64\x64dbg.exe', 'x64dbg\x32\x32dbg.exe', 'w64devkit\bin\gcc.exe',
                 'Ghidra.cmd', 'x64dbg.cmd', 'x32dbg.cmd', 'Devkit.cmd', 'data\fix-ghidra-paths.ps1')) {
    Write-Result (Test-Path -LiteralPath (Join-Path $Kit $f)) "exists: $f"
}

# The bundled JDK must be at least the version Ghidra declares.
$appProps = Join-Path $Kit 'ghidra\Ghidra\application.properties'
$minLine  = Select-String -Path $appProps -Pattern '^\s*application\.java\.min\s*=\s*(\d+)' | Select-Object -First 1
$need     = if ($minLine) { [int]$minLine.Matches[0].Groups[1].Value } else { 0 }
$jdkLine  = Select-String -Path (Join-Path $Kit 'jdk\release') -Pattern '^JAVA_VERSION="(\d+)' | Select-Object -First 1
$have     = if ($jdkLine) { [int]$jdkLine.Matches[0].Groups[1].Value } else { 0 }
Write-Result ($need -gt 0 -and $have -ge $need) "JDK $have satisfies Ghidra's minimum $need"

# --- portable paths ------------------------------------------------------------
function Test-PortableBlock {
    param([string]$Root, [string]$Label)
    $props = Get-Content (Join-Path $Root 'ghidra\support\launch.properties')
    $r     = $Root.TrimEnd('\') -replace '\\', '/'
    $begin = @($props | Where-Object { $_ -eq '#PORTABLE-BEGIN' }).Count
    $javaOverrides = @($props | Where-Object { $_ -match '^JAVA_HOME_OVERRIDE=' })
    Write-Result ($begin -eq 1) "$Label exactly one #PORTABLE block" "(found $begin)"
    Write-Result ($javaOverrides.Count -eq 1 -and $javaOverrides[0] -eq "JAVA_HOME_OVERRIDE=$r/jdk") `
        "$Label JAVA_HOME_OVERRIDE points at $r/jdk" "(found: $($javaOverrides -join '; '))"
    Write-Result ($props -contains "VMARGS=-Dapplication.settingsdir=`"$r/data/ghidra-settings`"") "$Label settingsdir points into the kit"
    Write-Result ($props -contains "VMARGS=-Duser.home=`"$r/data/home`"") "$Label user.home points into the kit"
}

function Invoke-LauncherFix {
    # Runs the exact fix-ghidra-paths command line from Ghidra.cmd, with ROOT set the way the
    # launcher sets it (%~dp0, which always ends in a backslash), without starting Ghidra itself.
    $line = Get-Content (Join-Path $Kit 'Ghidra.cmd') | Where-Object { $_ -match 'fix-ghidra-paths' } | Select-Object -First 1
    if (-not $line) { Write-Result $false 'Ghidra.cmd calls fix-ghidra-paths.ps1'; return }
    # Start from stale paths, so the check proves the launcher really rewrites them.
    $propsFile = Join-Path $Kit 'ghidra\support\launch.properties'
    $r = $Kit -replace '\\', '/'
    $stale = (Get-Content -LiteralPath $propsFile) | ForEach-Object { $_.Replace("$r/", 'X:/old-location/') }
    Set-Content -LiteralPath $propsFile -Value $stale -Encoding ASCII
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('launcher-' + [IO.Path]::GetRandomFileName() + '.cmd')
    Set-Content -LiteralPath $tmp -Encoding ASCII -Value @('@echo off', "set `"ROOT=$Kit\`"", $line, 'exit /b %errorlevel%')
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "`"$tmp`"" -NoNewWindow -Wait -PassThru
    Remove-Item -LiteralPath $tmp
    Write-Result ($p.ExitCode -eq 0) "Ghidra.cmd's fix-ghidra-paths line runs" "(exit $($p.ExitCode); line: $line)"
}

Write-Host "Portable paths"
Invoke-LauncherFix
Test-PortableBlock $Kit 'after launcher:'
# Re-applying must be idempotent (no duplicated lines).
& (Join-Path $Kit 'data\fix-ghidra-paths.ps1') -Root $Kit
Test-PortableBlock $Kit 're-applied:'

# --- compile the lab -----------------------------------------------------------
Write-Host "Compile lab (output in $OutDir)"
# Uses lab\Makefile with the kit's make, the same way a student builds from Devkit.cmd.
$make = Join-Path $Kit 'w64devkit\bin\make.exe'
$env:PATH = (Join-Path $Kit 'w64devkit\bin') + ';' + $env:PATH
$exes = @{}
if ($OutDir -match ' ') {
    Write-Result $false 'make lab' "(OUT path has a space, which make can't handle: $OutDir; pass -OutDir)"
} else {
    $outArg = 'OUT=' + ($OutDir.TrimEnd('\') -replace '\\', '/')
    $p = Start-Process -FilePath $make -ArgumentList '-C', "`"$LabSource`"", $outArg -NoNewWindow -Wait -PassThru
    Write-Result ($p.ExitCode -eq 0) 'make lab' "(exit $($p.ExitCode))"
    foreach ($name in 'ex1', 'ex2', 'ex3') {
        $exe = Join-Path $OutDir "$name.exe"
        $ok  = Test-Path -LiteralPath $exe
        Write-Result $ok "built $name.exe"
        if ($ok) { $exes[$name] = $exe }
    }
    # Nothing should be written next to the sources.
    $stray = @(Get-ChildItem -LiteralPath $LabSource -File | Where-Object { $_.Name -notmatch '\.c$|^Makefile$' })
    Write-Result ($stray.Count -eq 0) 'make left lab\ clean' "(found: $($stray.Name -join ', '))"
}

# --- Devkit.cmd opens the shell in the repo's lab folder ------------------------
Write-Host "Devkit.cmd"
function ConvertTo-Comparable { param([string]$Path) ($Path.Trim() -replace '\\', '/').TrimEnd('/').ToLowerInvariant() }
$labPathFile = Join-Path $Kit 'data\lab-path.txt'
$saved = if (Test-Path -LiteralPath $labPathFile) { (Get-Content -LiteralPath $labPathFile | Select-Object -First 1) } else { '' }
Write-Result ((ConvertTo-Comparable $saved) -eq (ConvertTo-Comparable $LabSource)) 'data\lab-path.txt points at the repo lab folder' `
    "(found '$saved', expected '$LabSource')"

# Run a copy of Devkit.cmd (in the kit root, so %~dp0 matches) with "start" removed, so its shell
# runs in this window; feed it "pwd" and check where the shell really is.
$probe = Join-Path $Kit ('devkit-probe-' + [IO.Path]::GetRandomFileName() + '.cmd')
$body  = (Get-Content -LiteralPath (Join-Path $Kit 'Devkit.cmd')) | ForEach-Object { $_ -replace '^(\s*)start\s+"[^"]*"\s+', '$1' }
Set-Content -LiteralPath $probe -Value $body -Encoding ASCII
try {
    $cases = @(
        @{ Name = 'no argument -> lab-path.txt'; Args = @();                                   Expect = $LabSource },
        @{ Name = 'argument -> that folder';     Args = @("`"$OutDir`"");                      Expect = $OutDir },
        @{ Name = 'missing folder -> kit lab\';  Args = @("`"$(Join-Path $OutDir 'nope')`"");  Expect = (Join-Path $Kit 'lab') }
    )
    foreach ($c in $cases) {
        $r   = Invoke-Program 'cmd.exe' @('pwd', 'exit') -Arguments (@('/c', "`"`"$probe`"") + $c.Args + @('"'))
        $cwd = (($r.Output -split "`n") | Where-Object { $_ -match '^\s*[A-Za-z]:[/\\]' } | Select-Object -Last 1)
        if ($null -eq $cwd) { $cwd = '' }
        Write-Result ((ConvertTo-Comparable $cwd) -eq (ConvertTo-Comparable $c.Expect)) "Devkit.cmd shell starts in: $($c.Name)" `
            "(expected '$($c.Expect)'; output: $($r.Output))"
    }
} finally {
    Remove-Item -LiteralPath $probe -ErrorAction SilentlyContinue
}

# --- run the practice programs -------------------------------------------------
Write-Host "Practice programs"
if ($exes['ex1']) {
    Test-Program 'ex1 right password' $exes['ex1'] @('hunter2-ghidra') 0 'Access granted!'
    Test-Program 'ex1 wrong password' $exes['ex1'] @('hunter2') 1 'Access denied.'
}
if ($exes['ex2']) {
    Test-Program 'ex2 alice/cfb71247'  $exes['ex2'] @('alice', 'cfb71247') 0 'Valid serial.'
    Test-Program 'ex2 wrong serial'    $exes['ex2'] @('alice', 'deadbeef') 1 'Invalid serial.'
    Test-Program 'ex2 short name'      $exes['ex2'] @('bob') 1 'at least 4 characters'
    # Cross-check the keygen against the program for another name, if Python is around.
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py) {
        $keygen = Join-Path $LabSource 'solutions\keygen_ex2.py'
        $serial = (& $py.Source -I $keygen 'reverser').Trim()
        Test-Program "ex2 keygen serial for 'reverser' ($serial)" $exes['ex2'] @('reverser', $serial) 0 'Valid serial.'
    } else {
        Write-Host "  SKIP  ex2 keygen cross-check (python not found)"
    }
}
if ($exes['ex3']) {
    Test-Program 'ex3 right key' $exes['ex3'] @('R3v3rs1ng_D4y1') 0 'License OK.'
    Test-Program 'ex3 wrong key' $exes['ex3'] @('R3v3rs1ng')      0 'Bad license key.'
}

# --- Ghidra headless import (optional, takes a minute or two) -------------------
if ($Headless) {
    Write-Host "Ghidra headless import"
    $target = $exes['ex1']
    if (-not $target) {
        Write-Result $false 'Ghidra headless import' '(ex1 did not compile)'
    } else {
        $projDir  = Join-Path $OutDir 'ghidra-proj'
        New-Item -ItemType Directory $projDir -Force | Out-Null
        $settings = Join-Path $Kit 'data\ghidra-settings'
        $appData  = if ($env:APPDATA) { Join-Path $env:APPDATA 'ghidra' } else { '' }
        $appDataBefore = $appData -and (Test-Path -LiteralPath $appData)
        $log = Join-Path $OutDir 'headless.log'
        $nul = Join-Path $OutDir 'empty.in'
        [IO.File]::WriteAllBytes($nul, [byte[]]@())   # empty stdin, so "Press any key" can't block
        # Same environment Ghidra.cmd sets up: the kit's JDK, not whatever Java the machine has.
        $env:JAVA_HOME = Join-Path $Kit 'jdk'
        $env:PATH      = (Join-Path $Kit 'jdk\bin') + ';' + $env:PATH
        $p = Start-Process -FilePath 'cmd.exe' -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log `
                -RedirectStandardInput $nul `
                -ArgumentList '/c', "`"`"$Kit\ghidra\support\analyzeHeadless.bat`" `"$projDir`" ci -import `"$target`" -deleteProject`""
        $text = Get-Content -LiteralPath $log -Raw
        if ($null -eq $text) { $text = '' }
        $tail = (($text -split "`n") | Select-Object -Last 15) -join "`n"
        Write-Result ($p.ExitCode -eq 0 -and $text -match 'Import succeeded') 'analyzeHeadless imports ex1' "(exit $($p.ExitCode))`n$tail"
        $settingsUsed = @(Get-ChildItem -LiteralPath $settings -Recurse -Force -ErrorAction SilentlyContinue).Count -gt 0
        Write-Result $settingsUsed 'Ghidra wrote its settings into data\ghidra-settings'
        if ($appData -and -not $appDataBefore) {
            Write-Result (-not (Test-Path -LiteralPath $appData)) 'Ghidra left %APPDATA%\ghidra alone'
        }
    }
}

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "$($script:Failures) check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "All checks passed." -ForegroundColor Green
