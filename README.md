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

- `lab/`: the practice programs, one folder per course day (`lab/day1/`: plain-text password, name-based serial, XOR-hidden key with an anti-debugging check). Spoilers and answer checks are in `lab/solutions/dayN/`.
- `docs/`: the [Day 1 training course](docs/day1-training.md) (Ghidra basics, x64dbg basics, a capstone) and the [roadmap](docs/roadmap.md) for the full 15-day course.

Requires Windows with PowerShell 5.1 or later. Use a VM for practice.

## Quick start

```powershell
# first build, or fill in anything missing
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable

# update everything to the latest versions (overwrites, never deletes)
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable -Force
```

You can run the script again safely: tools that are already installed are skipped, and your settings and plugins are kept.

## Building the practice programs

Open `RE-Portable\Devkit.cmd`. Its shell starts in this repo's `lab` folder (the build saves that location in `RE-Portable\data\lab-path.txt`; edit it if you move the repo, or run `Devkit.cmd D:\path\to\lab`). Then:

```sh
make                              # every day -> bin/day1/ex1.exe, bin/day1/ex2.exe, ...
make day1                         # one day
make OUT=E:/RE-Portable/lab       # or put them somewhere else (-> E:/RE-Portable/lab/day1/...)
make clean
```

The sources stay where they are. `make` rebuilds only what changed. Keep `OUT` free of spaces (make can't handle them) and use forward slashes.

Then analyze the programs with `Ghidra.cmd` and `x64dbg.cmd`.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
