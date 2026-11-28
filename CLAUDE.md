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
- `docs/day1-training.md` is the only copy of the training guide; edit it directly (the Claude doc it was exported from is retired). Keep it in step with `lab/` and the kit: program names, `make`, `Devkit.cmd`.
- Each course day has `lab/dayN/` (sources + a Makefile listing `PROGS`, using `lab/common.mk`) and `lab/solutions/dayN/` (spoilers + `checks.psd1`, the answers CI runs). Every program needs at least one check.
- `docs/primers/` holds background reading (numbered, indexed in `docs/primers/README.md`). Each day guide lists the primers it relies on under "Before you start"; a day that needs new background gets a new primer.
- `lab/solutions/` holds spoilers; the training docs link to it but don't inline answers outside the answer key.
- Run PSScriptAnalyzer on script changes when available, and test on Windows before saying something works.

## Layout
scripts/  build tooling      lab/  practice programs by day (+ solutions/)      tests/  CI checks      docs/  course material and roadmap
