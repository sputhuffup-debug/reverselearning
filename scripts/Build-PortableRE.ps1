<#
.SYNOPSIS
    Builds (or tops up) a self-contained, portable reverse-engineering kit:
      - Ghidra          (latest GitHub release)
      - Temurin JDK     (the version Ghidra requires, bundled so no Java install is needed)
      - x64dbg          (latest snapshot)
      - w64devkit       (portable GCC toolchain for compiling practice programs)
      - w64devkit32     (the same toolchain for 32-bit x86 programs)

    Safe to re-run. For each tool:
      - already installed (its main file is present)  -> skipped, nothing downloaded
      - folder exists but is incomplete                -> downloaded, and only MISSING files are added
      - folder missing                                 -> downloaded and installed
    Existing files are never overwritten unless you pass -Force, and nothing is ever deleted,
    so your x64dbg settings/plugins and Ghidra settings are kept.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Build-PortableRE.ps1
    powershell -ExecutionPolicy Bypass -File .\Build-PortableRE.ps1 -Destination D:\RE
    powershell -ExecutionPolicy Bypass -File .\Build-PortableRE.ps1 -Force     # update: overwrite with latest versions
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Force',
    Justification = 'Used by the helper functions (Install-Component, Merge-Tree, Write-IfMissing) via script scope.')]
param(
    [string]$Destination = (Join-Path (Get-Location) 'RE-Portable'),
    [int]$JdkVersion = 0,           # 0 = use the minimum JDK version the installed Ghidra declares
    [switch]$Force                  # download everything again and overwrite existing files (never deletes)
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # makes Invoke-WebRequest much faster on PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Headers = @{ 'User-Agent' = 'Build-PortableRE'; 'Accept' = 'application/vnd.github+json' }
# Optional: a token raises the GitHub API rate limit (60/hour unauthenticated). Used for API calls only, never downloads.
if ($env:GITHUB_TOKEN) { $Headers['Authorization'] = "Bearer $env:GITHUB_TOKEN" }

# --- helpers -----------------------------------------------------------------
function Get-LatestAsset {
    param([string]$Repo, [string]$Pattern)
    $rel   = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers
    $asset = $rel.assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
    if (-not $asset) { throw "No asset matching '$Pattern' in $Repo release $($rel.tag_name)" }
    Write-Host "  $Repo -> $($rel.tag_name) ($($asset.name))"
    $asset
}

function Get-AssetSha {
    param($Asset)
    if ($Asset.digest -match '^sha256:(.+)$') { $Matches[1] } else { $null }
}

function Save-File {
    param([string]$Url, [string]$OutFile, [string]$Sha256)
    Write-Host "  Downloading $(Split-Path $OutFile -Leaf)..."
    Invoke-WebRequest $Url -OutFile $OutFile -Headers @{ 'User-Agent' = 'Build-PortableRE' } -UseBasicParsing
    if ($Sha256) {
        $actual = (Get-FileHash $OutFile -Algorithm SHA256).Hash
        if ($actual -ne $Sha256.ToUpper()) { throw "SHA-256 mismatch for $OutFile`n expected $Sha256`n got      $actual" }
        Write-Host "  SHA-256 verified."
    }
}

function Expand-ToTemp {
    # Extracts a .zip (or a 7-Zip self-extracting .exe) into a fresh temp folder.
    # Returns the single top-level folder inside it, or the temp folder itself if there is more than one item.
    param([string]$Archive)
    $tmp = Join-Path $Work ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory $tmp | Out-Null
    if ($Archive -like '*.zip') {
        Expand-Archive $Archive -DestinationPath $tmp
    } else {
        $p = Start-Process -FilePath $Archive -ArgumentList "-o`"$tmp`"", '-y' -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -ne 0) { throw "Self-extractor $Archive failed with exit code $($p.ExitCode)" }
    }
    $items = @(Get-ChildItem $tmp -Force)
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $tmp }
}

function Merge-Tree {
    # Copies $Src into $Dst. Existing files are skipped (or overwritten with -Force). Nothing is deleted.
    param([string]$Src, [string]$Dst)
    $Src = (Resolve-Path -LiteralPath $Src).Path.TrimEnd('\')
    if (-not (Test-Path -LiteralPath $Dst)) { New-Item -ItemType Directory $Dst | Out-Null }
    $added = 0; $skipped = 0; $replaced = 0
    foreach ($item in Get-ChildItem -LiteralPath $Src -Recurse -Force) {
        $target = Join-Path $Dst $item.FullName.Substring($Src.Length + 1)
        if ($item.PSIsContainer) {
            if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory $target | Out-Null }
        } elseif (Test-Path -LiteralPath $target) {
            if ($Force) { Copy-Item -LiteralPath $item.FullName $target -Force; $replaced++ } else { $skipped++ }
        } else {
            Copy-Item -LiteralPath $item.FullName $target; $added++
        }
    }
    Write-Host "  Files added: $added, kept existing: $skipped, overwritten: $replaced"
}

function Install-Component {
    # $Fetch downloads + extracts and returns the folder whose contents belong in $Folder.
    param([string]$Name, [string]$Folder, [string]$Marker, [scriptblock]$Fetch)
    $dst = Join-Path $Destination $Folder
    if (-not $Force -and (Test-Path -LiteralPath (Join-Path $dst $Marker))) {
        Write-Host "  $Name already installed in $Folder\ - skipping."
        return
    }
    if (Test-Path -LiteralPath $dst) { Write-Host "  $Folder\ exists but is incomplete (or -Force); adding missing files." }
    $src = & $Fetch
    Merge-Tree $src $dst
}

function Write-IfMissing {
    param([string]$Path, [string]$Content)
    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        Write-Host "  $(Split-Path $Path -Leaf) exists - skipping."
        return
    }
    Set-Content -LiteralPath $Path $Content -Encoding ASCII
    Write-Host "  Wrote $(Split-Path $Path -Leaf)"
}

function Get-JdkMajor {
    # Reads JAVA_VERSION from <jdk>\release, returns the major version or 0 if unknown.
    param([string]$JdkDir)
    $rel = Join-Path $JdkDir 'release'
    if (-not (Test-Path $rel)) { return 0 }
    $m = Select-String -Path $rel -Pattern '^JAVA_VERSION="(\d+)' | Select-Object -First 1
    if ($m) { [int]$m.Matches[0].Groups[1].Value } else { 0 }
}

# --- folders (created only if missing) ---------------------------------------
if (-not (Test-Path -LiteralPath $Destination)) { New-Item -ItemType Directory $Destination | Out-Null }
foreach ($d in @('data\ghidra-settings', 'data\home', 'projects', 'lab')) {
    $p = Join-Path $Destination $d
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory $p | Out-Null }
}
$Destination = (Resolve-Path $Destination).Path
$Work = Join-Path $Destination '_download'
if (Test-Path $Work) { Remove-Item $Work -Recurse -Force }   # leftovers from an interrupted run
New-Item -ItemType Directory $Work | Out-Null

try {
    # --- Ghidra --------------------------------------------------------------
    Write-Host "[1/5] Ghidra"
    Install-Component 'Ghidra' 'ghidra' 'ghidraRun.bat' {
        $a = Get-LatestAsset 'NationalSecurityAgency/ghidra' '^ghidra_.*_PUBLIC_.*\.zip$'
        $f = Join-Path $Work $a.name
        Save-File $a.browser_download_url $f (Get-AssetSha $a)
        Expand-ToTemp $f
    }

    # --- JDK -----------------------------------------------------------------
    Write-Host "[2/5] Temurin JDK"
    if ($JdkVersion -eq 0) {
        $appProps = Join-Path $Destination 'ghidra\Ghidra\application.properties'
        $minLine  = Select-String -Path $appProps -Pattern '^\s*application\.java\.min\s*=\s*(\d+)' | Select-Object -First 1
        if (-not $minLine) { throw "Could not find application.java.min in $appProps; rerun with -JdkVersion NN" }
        $JdkVersion = [int]$minLine.Matches[0].Groups[1].Value
        Write-Host "  Ghidra requires JDK $JdkVersion+"
    }
    $jdkDir = Join-Path $Destination 'jdk'
    $have   = Get-JdkMajor $jdkDir
    if ($have -gt 0 -and $have -lt $JdkVersion) {
        # Mixing two JDK versions in one folder would break it, so set the old one aside instead.
        $old = "$jdkDir.old-$have"
        Write-Host "  Existing JDK $have is too old for this Ghidra; moving it to $(Split-Path $old -Leaf)\"
        Move-Item $jdkDir $old
    }
    Install-Component "JDK $JdkVersion" 'jdk' 'bin\java.exe' {
        $meta = Invoke-RestMethod "https://api.adoptium.net/v3/assets/latest/$JdkVersion/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse"
        $pkg  = $meta[0].binary.package
        Write-Host "  $($meta[0].release_name) ($($pkg.name))"
        $f = Join-Path $Work $pkg.name
        Save-File $pkg.link $f $pkg.checksum
        Expand-ToTemp $f
    }

    # --- x64dbg --------------------------------------------------------------
    Write-Host "[3/5] x64dbg"
    Install-Component 'x64dbg' 'x64dbg' 'x64\x64dbg.exe' {
        $a = Get-LatestAsset 'x64dbg/x64dbg' '^snapshot_.*\.zip$'
        $f = Join-Path $Work $a.name
        Save-File $a.browser_download_url $f (Get-AssetSha $a)
        $root = Expand-ToTemp $f
        $rel  = Join-Path $root 'release'
        if (Test-Path $rel) { $rel } else { $root }
    }

    # --- w64devkit (GCC) -----------------------------------------------------
    Write-Host "[4/5] w64devkit (GCC compiler)"
    Install-Component 'w64devkit' 'w64devkit' 'bin\gcc.exe' {
        # v2+ ships a 7-Zip self-extracting exe (w64devkit-x64-2.11.0.7z.exe); older versions shipped a .zip.
        $a = Get-LatestAsset 'skeeto/w64devkit' '^w64devkit-(x64-)?[\d.]+(\.7z)?\.(exe|zip)$'
        $f = Join-Path $Work $a.name
        Save-File $a.browser_download_url $f (Get-AssetSha $a)
        Expand-ToTemp $f
    }

    # --- w64devkit, 32-bit (GCC for x86) -----------------------------------------
    # The same toolchain built for 32-bit x86 (w64devkit-x86-<ver>.7z.exe; older releases named it
    # i686), for the course's 32-bit programs. Kept apart in w64devkit32\ so the two never mix.
    Write-Host "[5/5] w64devkit32 (32-bit GCC compiler)"
    try {
        Install-Component 'w64devkit32' 'w64devkit32' 'bin\gcc.exe' {
            $a = Get-LatestAsset 'skeeto/w64devkit' '^w64devkit-(x86|i686)-[\d.]+(\.7z)?\.(exe|zip)$'
            $f = Join-Path $Work $a.name
            Save-File $a.browser_download_url $f (Get-AssetSha $a)
            Expand-ToTemp $f
        }
    } catch {
        # Not fatal: the 64-bit kit is complete without it. Re-run the script later to add it.
        Write-Warning "32-bit w64devkit not installed: $($_.Exception.Message)"
    }

    # --- launchers (written only if missing) ---------------------------------
    Write-Host "Launchers"

    # Rewrites Ghidra's launch.properties with the kit's *current* location on every launch,
    # so the folder stays portable even if its drive letter or path changes.
    Write-IfMissing (Join-Path $Destination 'data\fix-ghidra-paths.ps1') @'
param([string]$Root)
$ErrorActionPreference = 'Stop'
# Tolerate a stray quote or trailing backslash from the caller's command line.
$Root  = $Root.Trim().Trim('"').TrimEnd('\')
$props = Join-Path $Root 'ghidra\support\launch.properties'
$r     = $Root -replace '\\', '/'
$out = @(); $skip = $false
foreach ($l in Get-Content $props) {
    if ($l -eq '#PORTABLE-BEGIN') { $skip = $true; continue }
    if ($l -eq '#PORTABLE-END')   { $skip = $false; continue }
    if (-not $skip -and $l -notmatch '^JAVA_HOME_OVERRIDE=') { $out += $l }
}
$out += '#PORTABLE-BEGIN'
$out += "JAVA_HOME_OVERRIDE=$r/jdk"
# launch.bat passes VMARGS to java unquoted (a space splits them), and Ghidra's LaunchSupport reads
# application.settingsdir literally (quotes would become part of the path). So a path with a space
# uses its 8.3 short form; without one, settings stay in %APPDATA%\ghidra.
$vm = $r
if ($r -match ' ') {
    $vm = $null
    try { $vm = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($Root).ShortPath -replace '\\', '/' } catch { $vm = $null }
    if ($vm -match ' ') { $vm = $null }
    if (-not $vm) { Write-Warning "Kit path has spaces and no 8.3 short name: Ghidra settings will be kept in %APPDATA%\ghidra." }
}
if ($vm) {
    $out += "VMARGS=-Dapplication.settingsdir=$vm/data/ghidra-settings"
    $out += "VMARGS=-Duser.home=$vm/data/home"
}
$out += '#PORTABLE-END'
Set-Content $props $out -Encoding ASCII
'@

    Write-IfMissing (Join-Path $Destination 'Ghidra.cmd') @'
@echo off
setlocal
set "ROOT=%~dp0"
rem Strip the trailing backslash: "C:\kit\" would reach PowerShell as C:\kit" (the \" escapes the quote).
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%data\fix-ghidra-paths.ps1" -Root "%ROOT:~0,-1%"
if errorlevel 1 (
    echo Could not update Ghidra's paths for this location. See the error above.
    pause
    exit /b 1
)
set "JAVA_HOME=%ROOT%jdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"
start "" "%ROOT%ghidra\ghidraRun.bat"
'@

    Write-IfMissing (Join-Path $Destination 'x64dbg.cmd') '@start "" "%~dp0x64dbg\x64\x64dbg.exe" %*'
    Write-IfMissing (Join-Path $Destination 'x32dbg.cmd') '@start "" "%~dp0x64dbg\x32\x32dbg.exe" %*'

    # Remember the lab folder of the repo this script is in, so Devkit.cmd can open the shell there.
    # It's a plain setting (edit it freely), not a path baked into a launcher; if the folder is
    # gone (kit moved to another PC), Devkit.cmd falls back to the kit's own lab\.
    $repoLab = Join-Path $PSScriptRoot '..\lab'
    if (Test-Path -LiteralPath (Join-Path $repoLab 'Makefile')) {
        $repoLab = (Resolve-Path -LiteralPath $repoLab).Path
        if ($repoLab -match '[^\x20-\x7E]') {
            Write-Host "  Not saving lab path (non-ASCII characters): $repoLab; pass it to Devkit.cmd instead."
        } else {
            Write-IfMissing (Join-Path $Destination 'data\lab-path.txt') $repoLab
        }
    }

    # Opens a GCC shell in the lab folder: the one given as an argument, else data\lab-path.txt,
    # else the kit's lab\. Opens w64devkit's Unix-style shell, or a cmd window with GCC on PATH
    # if there is no sh.exe. Devkit.cmd uses the 64-bit toolchain, Devkit32.cmd the 32-bit one.
    $devkitTemplate = @'
@echo off
setlocal
set "ROOT=%~dp0"
set "LAB=%~1"
if not defined LAB if exist "%ROOT%data\lab-path.txt" set /p LAB=<"%ROOT%data\lab-path.txt"
if not defined LAB set "LAB=%ROOT%lab"
if not exist "%LAB%\" (
    echo Lab folder not found: %LAB%
    echo Using %ROOT%lab instead. Edit data\lab-path.txt or run: Devkit.cmd D:\path\to\lab
    set "LAB=%ROOT%lab"
)
cd /d "%LAB%"
set "PATH=%ROOT%__DEVKIT__\bin;%PATH%"
rem A plain (non-login) shell, not w64devkit.exe: its login shell always starts in %HOME%.
if exist "%ROOT%__DEVKIT__\bin\sh.exe" (
    start "__DEVKIT__" "%ROOT%__DEVKIT__\bin\sh.exe"
) else (
    start "__DEVKIT__" cmd /k "gcc --version"
)
'@
    Write-IfMissing (Join-Path $Destination 'Devkit.cmd') ($devkitTemplate -replace '__DEVKIT__', 'w64devkit')
    if (Test-Path -LiteralPath (Join-Path $Destination 'w64devkit32\bin\gcc.exe')) {
        Write-IfMissing (Join-Path $Destination 'Devkit32.cmd') ($devkitTemplate -replace '__DEVKIT__', 'w64devkit32')
    }

    # Always re-apply paths (harmless if already set), so ghidraRun.bat also works when launched directly.
    & (Join-Path $Destination 'data\fix-ghidra-paths.ps1') -Root $Destination
}
finally {
    if (Test-Path $Work) { Remove-Item $Work -Recurse -Force }
}

Write-Host ""
Write-Host "Done: $Destination" -ForegroundColor Green
Write-Host "  Ghidra.cmd   - Ghidra with bundled JDK; settings in data\, save projects in projects\"
Write-Host "  x64dbg.cmd   - 64-bit debugger (x32dbg.cmd for 32-bit)"
Write-Host "  Devkit.cmd   - GCC shell opened in the repo's lab folder (see data\lab-path.txt); run 'make' there"
Write-Host "  Devkit32.cmd - the same with the 32-bit GCC (w64devkit32), for 32-bit programs"
