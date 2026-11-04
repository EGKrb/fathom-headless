# Fathom headless

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE) [![Platform: Windows](https://img.shields.io/badge/Platform-Windows%20x86%2Fx64-0078D6.svg)](#) [![Based on x64dbg](https://img.shields.io/badge/based%20on-x64dbg-444.svg)](https://github.com/x64dbg/x64dbg) [![Smoke test](https://github.com/EGKrb/fathom-headless/actions/workflows/smoke.yml/badge.svg)](https://github.com/EGKrb/fathom-headless/actions/workflows/smoke.yml)

**Fathom headless** is the **command-line edition** of [Fathom](https://github.com/EGKrb/Fathom), the reverse-engineering toolkit built on [x64dbg](https://github.com/x64dbg/x64dbg): `headless.exe` and the full debug engine for **x64 and x32**, without the Qt GUI. It debugs Windows programs from a script, from standard input, from PowerShell templates or from Python — on a server, in a sandbox VM, in CI, over SSH.

🌐 **Website:** <https://egkrb.github.io/fathom-headless/> · 🇫🇷 [Lire en français](README.fr.md) · [⬇ Latest release](https://github.com/EGKrb/fathom-headless/releases/latest)

```
PS> .\x64\headless.exe -cf trace.txt
...
Trace finished after 2000 steps!
Exported 2000 instructions (1 threads, 0 context switches) to C:\work\trace.json
Exported 2000 instructions (1 threads, 0 context switches) to C:\work\trace.log
```

| | Fathom | Fathom headless |
|---|---|---|
| Debug engine, commands, scripts, expressions | ✅ | ✅ (same build) |
| `TraceExport` → JSON / CSV / Tenet / Frinet / `.ftt` (Time Travel) | ✅ | ✅ |
| Time Travel: `tt.*` commands (seek, step back, find, memory at an instant) | ✅ | ✅ (commands; the tab needs the GUI) |
| Plugins: pybridge, ExtraCmds, ScyllaHide, xAnalyzer | ✅ | ✅ (ExtraCmds x64 without the GUI tab) |
| Script templates and launcher | ✅ | ✅ |
| Qt GUI (`x64dbg.exe`, `x32dbg.exe`), minidump viewer | ✅ | — |
| Download size | 72 MB | **15 MB** |

---

## Install

1. Download `fathom-headless_<version>.zip` from the [latest release](https://github.com/EGKrb/fathom-headless/releases/latest).
2. Extract it into a folder **you can write to** (e.g. `C:\Tools\fathom-headless`): like x64dbg, the engine keeps its settings and databases next to the executables unless you pass `-userdir`.
3. Use `x64\headless.exe` for 64-bit programs and `x32\headless.exe` for 32-bit programs.

```
fathom-headless\
  x64\  x32\            headless.exe, the engine (x64dbg.dll / x32dbg.dll, TitanEngine...), plugins\
  templates\            ready-made x64dbg scripts
  run-headless.ps1      runs a template against a target
  pybridge\             Python client and examples (pybridge plugin)
  hvkdfusion\  tools\   HvKdFusion / wineye scripts, PE-sieve
  licenses\             licenses of x64dbg and of the bundled components
```

## Four ways to use it

### 1. A script

```
// trace.txt
init "C:\samples\target.exe"
StartTraceRecording "C:\work\trace.trace64"
TraceIntoConditional 0, .2000
StopTraceRecording
TraceExport "C:\work\trace.trace64", "C:\work\trace.json"
TraceExport "C:\work\trace.trace64", "C:\work\trace.log", tenet
TraceExport "C:\work\trace.trace64", "C:\work\trace.ftt", ftt
tt.open "C:\work\trace.ftt"
tt.seek .1500
tt.regs
```

```powershell
.\x64\headless.exe -cf C:\work\trace.txt
```

`headless.exe` runs the script, then keeps reading commands from standard input; it exits when standard input is closed (`exit` or Ctrl+Z, Enter).

### 2. Interactive

```
PS> .\x64\headless.exe
init C:\samples\target.exe
bp kernelbase.CreateFileW
run
run
log "file: {utf16@rcx}"
StepOver
exit
```

`init` stops at the system breakpoint, the first `run` at the entry point, the second one in `CreateFileW`, where `rcx` holds the first argument (x64).

Every x64dbg command works: breakpoints (`bp`, `bph`, `bpm`), stepping (`StepInto`, `StepOver`, `StepOut`, `run`), memory (`savedata`, `findallmem`), tracing, `TraceExport`, the plugin commands (`pybridge.start`, `.init`, `scylla_hide.enable`, `xanal`...). Numbers are **hexadecimal** by default (`.100` = 100 decimal). See the [x64dbg command reference](https://help.x64dbg.com/en/latest/commands/).

### 3. Templates

```powershell
.\run-headless.ps1 -Template api-log -Target C:\Windows\System32\whoami.exe
.\run-headless.ps1 -Template trace-export -Target .\program32.exe -Arch x32
```

The launcher fills in `%TARGET%`, `%MODULE%`, `%OUT%` and `%BITS%`, runs `headless.exe -cf` with an **isolated settings folder** and writes everything to `out\<template>-<date>\` (`script.txt`, `headless.log`, produced files). It prints which `headless.exe` it uses: the package's own one, else `-X64dbgDir`, `X64DBG_DIR` or an x64dbg installed with winget.

| Template | Purpose |
|---|---|
| `api-log` | logs API calls with their arguments, without pausing |
| `hook-apis-extended` | wider `api-log` (process/thread control, loader, memory, I/O, registry, crypto) |
| `trace-export` | traces up to 50,000 instructions from the entry point (or until the process exits) and exports JSON, CSV, Tenet and `.ftt` |
| `run-trace` | records up to 100,000 instructions and exports JSON and CSV |
| `dump-module` | saves the main module (`.mem`) and a full minidump at the entry point |
| `dump-at-delay` | lets the target run, then dumps the main module and a minidump (packers that unpack at startup) |
| `hook-unpack` | logs the typical runtime-unpacking APIs (`VirtualAlloc`, `VirtualProtect`, `WriteProcessMemory`, `NtMapViewOfSection`, `CryptDecrypt`...) |
| `unpack-dump` | dumps the last region that `VirtualProtect` flips to PAGE_EXECUTE* |
| `break-on-file` | conditional breakpoint on a file open, then log, stack save and minidump |
| `antidebug` | hides the debugger (`hide`: patched PEB) and logs anti-debug probes |
| `find-pattern` | searches a hex pattern (with wildcards) or an ASCII literal over the whole memory map |
| `emulate-dump` | emulates a `.dmp` with pybridge and serves it on 127.0.0.1:27041 |

### 4. Python (pybridge)

```python
import sys
sys.path.insert(0, r"C:\Tools\fathom-headless\pybridge\python")
from x64dbg_bridge import Debugger

with Debugger.launch(r"C:\Tools\fathom-headless") as dbg:     # starts x64\headless.exe
    dbg.init(r"C:\Windows\System32\whoami.exe")
    dbg.set_breakpoint("kernelbase.CreateFileW")
    if dbg.run(wait=True, timeout=10):
        print(dbg.regs())
```

See [pybridge](https://github.com/EGKrb/pybridge) for the full Python API.

## Command-line options

| Option | Effect |
|---|---|
| `headless.exe <program> [arguments]` | starts debugging a program |
| `-cf <script>` | runs a script file at startup |
| `-c "<command>"` | runs one command at startup |
| `-pid <n>` (`-p`, `-a`) | attaches to a running process |
| `-workingDir <dir>` | working directory of the started process |
| `-userdir <dir>` | settings and databases folder (default: next to `headless.exe`) |
| `-plugin <path>` | loads an extra plugin (repeatable) |
| `-help` | lists the options |

## Notes

- **ExtraCmds (x64)** is the commands-only build: `.init`, `.save`, `scylla_hide.*`, `hvkd*`, `wineye` and the Time Travel commands `tt.*` work; the HvKdFusion and Time Travel tabs of Fathom need the GUI.
- **Antivirus:** debuggers write into the memory of the process they debug, which behaviour monitors can take for injection. During testing, Microsoft Defender reported `Behavior:Win32/SuspLummaInj.A` when the 32-bit engine debugged a 32-bit Windows binary (`C:\Windows\SysWOW64\whoami.exe`), killed the debuggee and quarantined `x32\headless.exe`. Debugging other programs (and 64-bit system binaries) was not affected. For malware analysis, work in a VM and add an exclusion for the package folder there.
- Use it on programs you are allowed to analyse (your own software, malware samples in a sandbox, CTF challenges...).

## Building the package

The package is assembled from a Fathom build by [`tools/make-headless.ps1`](tools/make-headless.ps1): it keeps the engine, its DLLs and plugins, drops the Qt GUI, and adds this repository's launcher, templates and docs.

```powershell
# from the release folder of a Fathom build (tools\make-release.ps1 in Fathom), with a commands-only ExtraCmds x64
.\tools\make-headless.ps1 -Source C:\src\Fathom\release\release -Version 1.1.0 `
    -ExtraCmdsX64 C:\src\Fathom\extracmds\build-x64-noqt\ExtraCmds.dp64

# or from an extracted Fathom_<version>.zip: -Source is its "release" folder, the one that holds x64\ and x32\
# (the 64-bit ExtraCmds is then left out)
.\tools\make-headless.ps1 -Source C:\Downloads\Fathom\release
```

Microsoft WinDbg (`hvkdfusion\windbg64`) is never copied into the package: it is not redistributable, and `hvkdfusion.py setup` installs it. ntoseye and the Dokany installer (`hvkdfusion\ntoseye`, `hvkdfusion\dokany`) are left out too: they are only needed for WSL kernel debugging and for mounting memory as a drive, and ship with the full Fathom release; MemProcFS and hvlib (`hvkdfusion\memprocfs`, `hvkdfusion\hvlib`), used by wineye, are kept. The commands-only ExtraCmds is built in Fathom with `cmake -S extracmds -B extracmds\build-x64-noqt -DCMAKE_DISABLE_FIND_PACKAGE_Qt5=ON ...`.

## Tests

[`tests/smoke.ps1`](tests/smoke.ps1) runs [`tests/smoke.txt`](tests/smoke.txt) against [`tests/target.c`](tests/target.c): start, trace 2,000 instructions, export JSON, Tenet and `.ftt`, check the plugins. GitHub Actions builds the package from the latest Fathom release and runs it on x64 and x32 on every push.

```powershell
.\tests\smoke.ps1 -Package dist\fathom-headless -Target .\target64.exe -Arch x64
```

## License

GPL-3.0-or-later — see [LICENSE](LICENSE). Fathom headless is a modified distribution of [x64dbg](https://github.com/x64dbg/x64dbg) (GPL-3.0); the bundled components keep their own licenses (`licenses\`).
