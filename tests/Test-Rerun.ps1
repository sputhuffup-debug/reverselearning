<#
.SYNOPSIS
    Checks that re-running Build-PortableRE.ps1 on an existing kit is safe:
      - installed tools are skipped (nothing downloaded for them)
      - a tool with a missing file is topped up (only that tool is downloaded)
      - files the user added are kept, and existing files are not overwritten

    Modifies the kit it is given (removes x64dbg\x64\x64dbg.exe, adds a fake plugin and settings
    file), so point it at a throwaway kit.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\tests\Test-Rerun.ps1 -Kit $env:TEMP\RE-Portable
#>
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Kit)

$ErrorActionPreference = 'Stop'
$Kit   = (Resolve-Path -LiteralPath $Kit).Path.TrimEnd('\')
$build = Join-Path $PSScriptRoot '..\scripts\Build-PortableRE.ps1'
$script:Failures = 0

function Write-Result {
    param([bool]$Ok, [string]$Name, [string]$Detail = '')
    if ($Ok) { Write-Host "  PASS  $Name" -ForegroundColor Green; return }
    $script:Failures++
    Write-Host "  FAIL  $Name  $Detail" -ForegroundColor Red
    if ($env:GITHUB_ACTIONS) {
        $msg = ("$Name $Detail" -replace '%', '%25' -replace "`r", '' -replace "`n", '%0A')
        Write-Host "::error title=Test-Rerun::$msg"
    }
}

function Invoke-Build {
    # Runs the build script in a child Windows PowerShell and returns its console output as one string.
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $build -Destination $Kit
    $code = $LASTEXITCODE
    $text = ($out | Out-String)
    Write-Host $text
    Write-Result ($code -eq 0) 'build script exits 0' "(exit $code)"
    $text
}

# Things a user might have in their kit.
$x64       = Join-Path $Kit 'x64dbg\x64'
$plugin    = Join-Path $x64 'plugins\user-plugin.dp64'
$userIni   = Join-Path $x64 'x64dbg.ini'
$launcher  = Join-Path $Kit 'x64dbg.cmd'
New-Item -ItemType Directory (Split-Path $plugin) -Force | Out-Null
Set-Content -LiteralPath $plugin  -Value 'user plugin, must survive'
Set-Content -LiteralPath $userIni -Value '[Engine]' , 'UserSetting=1'
Add-Content -LiteralPath $launcher -Value 'rem user edit, must survive'
$launcherBefore = Get-Content -LiteralPath $launcher -Raw

Write-Host "Re-run with everything installed"
$text = Invoke-Build
$skips = ([regex]::Matches($text, 'already installed in .* - skipping')).Count
Write-Result ($skips -eq 5) 'all five tools skipped' "(skipped $skips)"
Write-Result ($text -notmatch 'Downloading') 'nothing downloaded'

Write-Host "Re-run with x64dbg.exe missing"
Remove-Item -LiteralPath (Join-Path $x64 'x64dbg.exe')
$text = Invoke-Build
$skips = ([regex]::Matches($text, 'already installed in .* - skipping')).Count
Write-Result ($skips -eq 4) 'the other four tools skipped' "(skipped $skips)"
Write-Result ($text -match 'Downloading snapshot_') 'x64dbg downloaded again'
Write-Result ($text -match 'Files added: 1, kept existing: \d+, overwritten: 0') 'only the missing file added' `
    "(merge line: $([regex]::Match($text, 'Files added:.*').Value))"
Write-Result (Test-Path -LiteralPath (Join-Path $x64 'x64dbg.exe')) 'x64dbg.exe restored'

Write-Host "User files"
Write-Result (Test-Path -LiteralPath $plugin) 'user plugin kept'
Write-Result ((Get-Content -LiteralPath $userIni) -contains 'UserSetting=1') 'user x64dbg.ini kept unchanged'
Write-Result ((Get-Content -LiteralPath $launcher -Raw) -eq $launcherBefore) 'edited launcher not overwritten'

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "$($script:Failures) check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "All checks passed." -ForegroundColor Green
