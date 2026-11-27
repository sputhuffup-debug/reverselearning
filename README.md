# reverselearning (portable-re-lab)

A portable reverse-engineering lab kit for Windows, plus a beginner training course that uses it.

## What you get

`scripts/Build-PortableRE.ps1` builds a self-contained `RE-Portable\` folder with:

- **Ghidra** (latest release)
- **Eclipse Temurin JDK**, at the version Ghidra requires
- **x64dbg** (latest snapshot)
- **w64devkit**, a portable GCC toolchain for compiling the practice programs
- Launchers: `Ghidra.cmd`, `x64dbg.cmd`, `x32dbg.cmd`, `Devkit.cmd`

Nothing is installed on the system. You can move the folder to another drive or PC, and Ghidra's settings stay inside it.

The repo also has:

- `lab/`: three small C practice programs that get harder in turn (plain-text password, name-based serial, XOR-hidden key with an anti-debugging check). Spoilers are in `lab/solutions/`.
- `docs/`: the Day 1 training course (Ghidra basics, x64dbg basics, a capstone).

Requires Windows with PowerShell 5.1 or later. Use a VM for practice.

## Quick start

```powershell
# first build, or fill in anything missing
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable

# update everything to the latest versions (overwrites, never deletes)
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable -Force
```

You can run the script again safely: tools that are already installed are skipped, and your settings and plugins are kept.

Copy `lab\*.c` into `RE-Portable\lab\`, open `RE-Portable\Devkit.cmd`, and compile, for example:

```sh
gcc -O0 -s ex1_password.c -o ex1.exe
```

Then analyze the result with `Ghidra.cmd` and `x64dbg.cmd`.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
