# HANDOFF: portable-re-lab

This file moves a project started in a Claude chat into a new GitHub repository worked on with Claude Code. It has everything needed to rebuild the repo: what the project is, decisions and lessons so far, the target layout, a backlog, and the full contents of every file. Nothing else from the chat is needed.

**How to use this file**

1. Create an empty folder (for example `E:\src\portable-re-lab`) and put this file in it as `HANDOFF.md`.
2. Open Claude Code in that folder and paste the bootstrap prompt from section 7.
3. Claude Code creates the files, makes the first commit and, if you want, creates the GitHub repo with `gh`.

---

## 1. What the project is

A **portable reverse-engineering lab kit for Windows**, plus a **training course** that uses it.

- **`scripts/Build-PortableRE.ps1`** builds a self-contained folder (`RE-Portable\`) holding:
  - **Ghidra** (latest GitHub release)
  - **Eclipse Temurin JDK**, at the version Ghidra declares it needs
  - **x64dbg** (latest snapshot)
  - **w64devkit**, a portable GCC toolchain for compiling the practice programs
  - launchers: `Ghidra.cmd`, `x64dbg.cmd`, `x32dbg.cmd`, `Devkit.cmd`
  - The folder can be moved to another drive or PC. Nothing gets installed on the system, and Ghidra's settings stay inside the kit.
- **`lab/`**: three small C practice programs that get harder in turn (a plain-text password, a serial worked out from a name, an XOR-hidden key with an anti-debugging check).
- **`docs/day1-training.md`**: a 7-hour Day 1 course (Ghidra basics, x64dbg basics, and a capstone where you solve and patch `ex3`), with an answer key.

Audience: beginners learning reverse engineering on their own practice programs, inside a Windows VM.

## 2. Decisions so far

| Topic | Decision | Why |
| --- | --- | --- |
| Platform | Windows-only (PowerShell 5.1+) | x64dbg only runs on Windows |
| Ghidra's JDK | Read `application.java.min` from `ghidra\Ghidra\application.properties`; `-JdkVersion` overrides it | A fixed JDK 21 broke once Ghidra 12 started requiring JDK 25 |
| JDK vendor | Eclipse Temurin, through the Adoptium API (`/v3/assets/latest/<N>/hotspot`) | Official zip builds with SHA-256 checksums |
| Portability | `data\fix-ghidra-paths.ps1` rewrites a `#PORTABLE-BEGIN`/`#PORTABLE-END` block in `ghidra\support\launch.properties` on every launch (`JAVA_HOME_OVERRIDE`, `-Dapplication.settingsdir`, `-Duser.home`) | Paths must follow the folder when it moves or the drive letter changes |
| Running it again | Each tool has a marker file. If the marker is there, the tool is skipped. If the folder is there but incomplete, only missing files are added. Nothing is ever deleted. `-Force` downloads again and overwrites, but still deletes nothing | Keeps users' x64dbg plugins and settings and Ghidra settings safe |
| JDK too old | The old `jdk\` folder is renamed to `jdk.old-<ver>` and a fresh one is installed | Merging two JDK versions in one folder would break it |
| Integrity | SHA-256 is checked against the GitHub `digest` field and the Adoptium `checksum` when they're available | Supply-chain hygiene |
| Practice binaries | Built with `gcc -O0 -s` | `-O0` keeps the code close to the source; `-s` strips names so students recover them |
| Docs | The training guide is Markdown in `docs/` | Lives with the code, readable on GitHub |

## 3. Known issues and lessons

- **Asset names change over time.** w64devkit went from `.zip` to `w64devkit-x64-<ver>.7z.exe`, a 7-Zip self-extractor run with `-o<dir> -y`. x64dbg moved to date-named releases (for example `2026.05.27`) but still ships `snapshot_<date>.zip`, next to a `symbols-snapshot_*.zip` that must be excluded. Current patterns:
  - Ghidra `^ghidra_.*_PUBLIC_.*\.zip$`
  - x64dbg `^snapshot_.*\.zip$`
  - w64devkit `^w64devkit-(x64-)?[\d.]+(\.7z)?\.(exe|zip)$`
- **Latest versions on 2026-11-26:** Ghidra 12.1.4 (needs JDK 25), Temurin 25.0.5.1+2, x64dbg 2026.05.27, w64devkit 2.11.0.
- **Not yet verified on Windows:**
  - the w64devkit self-extraction step
  - whether `-Dapplication.settingsdir` really moves Ghidra's settings (if it doesn't, settings fall back to `%APPDATA%\ghidra`)
  - the menu paths and shortcuts in the training guide, which were written from memory
- **Skipping doesn't check versions.** Running the script again never upgrades a tool that's already installed; you need `-Force`. See backlog item 1.
- The practice programs were tested on Linux, with `IsDebuggerPresent` stubbed out for ex3. Expected answers: ex1 `hunter2-ghidra`; ex2 serial for `alice` = `cfb71247`; ex3 key `R3v3rs1ng_D4y1`.

## 4. Target repository layout

```
portable-re-lab/
├── CLAUDE.md                  # standing instructions for Claude Code (section 8)
├── README.md                  # user-facing quick start (write it from sections 1 and 6)
├── HANDOFF.md                 # this file; keep it as history
├── .gitignore
├── scripts/
│   └── Build-PortableRE.ps1
├── lab/
│   ├── ex1_password.c
│   ├── ex2_serial.c
│   ├── ex3_crackme.c
│   └── solutions/
│       └── keygen_ex2.py      # spoiler
└── docs/
    └── day1-training.md       # export of the training doc (see section 7, step 4)
```

## 5. Backlog (in priority order)

1. **Version-aware updates.** Store the installed version for each tool (for example in `data\versions.json`), compare it with the latest release, and offer an `-Update` switch that upgrades only the tools that are out of date. Add a `-Check` switch that reports versions and installs nothing.
2. **CI on `windows-latest`** (GitHub Actions): run PSScriptAnalyzer, run the build script into a temp folder, compile `lab/*.c` with the installed w64devkit, and smoke-test each `.exe` by piping in the known answers.
3. **`lab/build.cmd`**: compile all the practice programs in one step from `Devkit.cmd`.
4. **Check the training guide** against Ghidra 12.1 and x64dbg 2026.05: menu paths, shortcuts, the Set Image Base icon, and Hide debugger (PEB).
5. **Day 2 content:** the same programs at `-O2`, a first Ghidra script (decode ex3's key automatically), and beginner crackmes from crackmes.one inside the VM.
6. Optional: an `-IncludeRetSync` switch to install the ret-sync plugin, which keeps Ghidra and x64dbg in step.

## 6. Usage (for the README)

```powershell
# first build, or fill in anything missing
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable
# update everything to the latest versions (overwrites, never deletes)
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable -Force
```

Then use `RE-Portable\Devkit.cmd` to compile the lab, and `Ghidra.cmd` and `x64dbg.cmd` to analyze it.

## 7. Bootstrap

**Step 1: prerequisites.** Git and, optionally, the GitHub CLI (`gh auth login` done).

**Step 2: paste this prompt into Claude Code:**

```text
Read HANDOFF.md in this folder. Set up the repository it describes:
1. Create every file in section 9 at the path given in its heading, with exactly the contents in its code block.
2. Create CLAUDE.md from section 8 and README.md from sections 1 and 6 (short, user-facing).
3. git init, commit everything as "Initial import from Claude chat handoff".
4. Ask me whether to create the GitHub repo; if yes run:
   gh repo create portable-re-lab --private --source . --push
Don't change the script's logic during the import. Afterwards, list the backlog from section 5 and ask which item to start.
```

**Step 3: GitHub by hand (if you don't use `gh`).** Create an empty repo on github.com, then run:

```bash
git remote add origin https://github.com/<you>/portable-re-lab.git
git branch -M main
git push -u origin main
```

**Step 4: the training guide.** Open the Day 1 doc in Claude, use the Export menu → Markdown, and save it as `docs/day1-training.md`. Then ask Claude Code to replace its three embedded C listings with links to `../lab/*.c`, so the code lives in one place.

## 8. CLAUDE.md (contents for the file)

```markdown
# portable-re-lab

Portable Windows reverse-engineering kit (Ghidra + Temurin JDK + x64dbg + w64devkit) built by
`scripts/Build-PortableRE.ps1`, plus practice programs in `lab/` and training docs in `docs/`.

## Rules
- Target Windows PowerShell 5.1 (no PS7-only syntax: no `??`, ternary, `-Parallel`, `&&`). Keep `$ErrorActionPreference = 'Stop'`.
- The build script must stay safe to re-run: never delete user files; skip what is installed; `-Force` overwrites but never deletes.
- Always discover the latest releases through APIs (GitHub releases/latest, Adoptium); never hardcode versions or URLs to specific builds.
- Verify SHA-256 when the source publishes one.
- Keep the kit relocatable: no absolute paths baked in at build time except inside the `#PORTABLE` block that
  `data\fix-ghidra-paths.ps1` rewrites on every launch.
- Practice programs are educational and benign. Don't add real malware or techniques aimed at real software.
- `lab/solutions/` holds spoilers; the training docs link to it but don't inline answers outside the answer key.
- Run PSScriptAnalyzer on script changes when available, and test on Windows before saying something works.

## Layout
scripts/  build tooling      lab/  practice C sources (+ solutions/)      docs/  course material
```

## 9. File contents

### `.gitignore`

````gitignore
# Built kit and downloads
RE-Portable/
_download/

# Compiled practice programs and patched copies
*.exe
*.obj
*.o

# Ghidra project files
*.gpr
*.rep/
*.lock
*.lock~

# OS / editor
Thumbs.db
.DS_Store
.vscode/
````

### `scripts/Build-PortableRE.ps1`

````powershell
<#
.SYNOPSIS
    Builds (or tops up) a self-contained, portable reverse-engineering kit:
      - Ghidra          (latest GitHub release)
      - Temurin JDK     (the version Ghidra requires, bundled so no Java install is needed)
      - x64dbg          (latest snapshot)
      - w64devkit       (portable GCC toolchain for compiling practice programs)

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
param(
    [string]$Destination = (Join-Path (Get-Location) 'RE-Portable'),
    [int]$JdkVersion = 0,           # 0 = use the minimum JDK version the installed Ghidra declares
    [switch]$Force                  # download everything again and overwrite existing files (never deletes)
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # makes Invoke-WebRequest much faster on PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Headers = @{ 'User-Agent' = 'Build-PortableRE'; 'Accept' = 'application/vnd.github+json' }

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
    Write-Host "[1/4] Ghidra"
    Install-Component 'Ghidra' 'ghidra' 'ghidraRun.bat' {
        $a = Get-LatestAsset 'NationalSecurityAgency/ghidra' '^ghidra_.*_PUBLIC_.*\.zip$'
        $f = Join-Path $Work $a.name
        Save-File $a.browser_download_url $f (Get-AssetSha $a)
        Expand-ToTemp $f
    }

    # --- JDK -----------------------------------------------------------------
    Write-Host "[2/4] Temurin JDK"
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
    Write-Host "[3/4] x64dbg"
    Install-Component 'x64dbg' 'x64dbg' 'x64\x64dbg.exe' {
        $a = Get-LatestAsset 'x64dbg/x64dbg' '^snapshot_.*\.zip$'
        $f = Join-Path $Work $a.name
        Save-File $a.browser_download_url $f (Get-AssetSha $a)
        $root = Expand-ToTemp $f
        $rel  = Join-Path $root 'release'
        if (Test-Path $rel) { $rel } else { $root }
    }

    # --- w64devkit (GCC) -----------------------------------------------------
    Write-Host "[4/4] w64devkit (GCC compiler)"
    Install-Component 'w64devkit' 'w64devkit' 'bin\gcc.exe' {
        # v2+ ships a 7-Zip self-extracting exe (w64devkit-x64-2.11.0.7z.exe); older versions shipped a .zip.
        $a = Get-LatestAsset 'skeeto/w64devkit' '^w64devkit-(x64-)?[\d.]+(\.7z)?\.(exe|zip)$'
        $f = Join-Path $Work $a.name
        Save-File $a.browser_download_url $f (Get-AssetSha $a)
        Expand-ToTemp $f
    }

    # --- launchers (written only if missing) ---------------------------------
    Write-Host "Launchers"

    # Rewrites Ghidra's launch.properties with the kit's *current* location on every launch,
    # so the folder stays portable even if its drive letter or path changes.
    Write-IfMissing (Join-Path $Destination 'data\fix-ghidra-paths.ps1') @'
param([string]$Root)
$Root  = $Root.TrimEnd('\')
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
$out += "VMARGS=-Dapplication.settingsdir=$r/data/ghidra-settings"
$out += "VMARGS=-Duser.home=$r/data/home"
$out += '#PORTABLE-END'
Set-Content $props $out -Encoding ASCII
'@

    Write-IfMissing (Join-Path $Destination 'Ghidra.cmd') @'
@echo off
setlocal
set "ROOT=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%data\fix-ghidra-paths.ps1" -Root "%ROOT%"
set "JAVA_HOME=%ROOT%jdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"
start "" "%ROOT%ghidra\ghidraRun.bat"
'@

    Write-IfMissing (Join-Path $Destination 'x64dbg.cmd') '@start "" "%~dp0x64dbg\x64\x64dbg.exe" %*'
    Write-IfMissing (Join-Path $Destination 'x32dbg.cmd') '@start "" "%~dp0x64dbg\x32\x32dbg.exe" %*'

    # Opens a GCC shell in the lab folder. w64devkit.exe gives a Unix-style shell (v2+);
    # if it's missing (older versions), fall back to a cmd window with GCC on PATH.
    Write-IfMissing (Join-Path $Destination 'Devkit.cmd') @'
@echo off
setlocal
set "ROOT=%~dp0"
cd /d "%ROOT%lab"
if exist "%ROOT%w64devkit\w64devkit.exe" (
    start "" "%ROOT%w64devkit\w64devkit.exe"
) else (
    set "PATH=%ROOT%w64devkit\bin;%PATH%"
    start "w64devkit" cmd /k "gcc --version"
)
'@

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
Write-Host "  Devkit.cmd   - GCC shell opened in lab\ (compile the practice programs here)"
````

### `lab/ex1_password.c`

````c
#include <stdio.h>
#include <string.h>

int main(void) {
    char input[64];
    printf("Enter password: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;
    if (strcmp(input, "hunter2-ghidra") == 0) {
        puts("Access granted!");
        return 0;
    }
    puts("Access denied.");
    return 1;
}
````

### `lab/ex2_serial.c`

````c
#include <stdio.h>
#include <string.h>

static unsigned int make_serial(const char *name) {
    unsigned int h = 0x1337;
    for (size_t i = 0; name[i]; i++)
        h = h * 31 + (unsigned char)name[i];
    return h ^ 0xC0FFEE;
}

int main(void) {
    char name[64];
    unsigned int serial;
    printf("Name: ");
    if (!fgets(name, sizeof name, stdin)) return 1;
    name[strcspn(name, "\r\n")] = 0;
    if (strlen(name) < 4) { puts("Name must be at least 4 characters."); return 1; }
    printf("Serial (hex): ");
    if (scanf("%x", &serial) != 1) return 1;
    if (serial == make_serial(name)) { puts("Valid serial. Thanks for registering!"); return 0; }
    puts("Invalid serial.");
    return 1;
}
````

### `lab/ex3_crackme.c`

````c
#include <stdio.h>
#include <string.h>
#include <windows.h>

static const unsigned char secret[] = {
    0x10, 0x71, 0x34, 0x71, 0x30, 0x31, 0x73, 0x2C, 0x25, 0x1D, 0x06, 0x76, 0x3B, 0x73
};

static void decode(char *out, size_t n) {
    for (size_t i = 0; i < n; i++) out[i] = (char)(secret[i] ^ 0x42);
    out[n] = 0;
}

int main(void) {
    char input[64];
    char key[sizeof secret + 1];

    if (IsDebuggerPresent()) {
        puts("Debugger detected. Bye.");
        return 2;
    }
    printf("License key: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;

    decode(key, sizeof secret);
    if (strcmp(input, key) == 0) puts("License OK. Welcome!");
    else puts("Bad license key.");
    return 0;
}
````

### `lab/solutions/keygen_ex2.py`

````python
"""Keygen for ex2_serial (Day 1, Exercise 1.2). SPOILER: solution file."""
import sys


def serial(name: str) -> int:
    h = 0x1337
    for c in name.encode():
        h = (h * 31 + c) & 0xFFFFFFFF
    return h ^ 0xC0FFEE


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: keygen_ex2.py NAME")
    print(format(serial(sys.argv[1]), "x"))
````

