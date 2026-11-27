# Changelog

## [1.4.1] - 2026-11-27

Built from [Fathom](https://github.com/EGKrb/Fathom) 1.11.1 (commit `1dd09ec4`).

- **TitanEngine fix**: the debug loop kept the continue code of the previous
  event; after an exception deferred with `DBG_REPLY_LATER`, the next thread
  creation was replied the same and Windows delivered it again and again, so
  `TraceSetThreads all` could hang (x32). Every event now starts with
  `DBG_CONTINUE`.
- NoVmp reports a VMProtect 3.6 - 3.11 VM entry clearly instead of asserting
  (it devirtualizes VMProtect 3.0 - 3.5); `NOVMP_DEBUG_VMENTER=1` dumps it.

## [1.4.0] - 2026-11-27

Built from [Fathom](https://github.com/EGKrb/Fathom) 1.11.0 (commit `21b031bb`).

- **Analysis tools** (Fathom 1.10 and 1.11): the package ships `novmp\`
  (NoVmp and NoVmp32 with vtildump: VMProtect 3.0 - 3.5 devirtualized to VTIL,
  x64 and x86), `remill\` (remill-lift-17 and its semantics: `remill.lift`),
  `analysis\` (angr and miasm: `angr.*`, `miasm.*`, Python 3.10+) and
  `binja\` (the `binja` command, the Binary Ninja plugin); the Triton and
  Decompiler (Ghidra) plugins are in `x64\plugins` and `x32\plugins`. Each tool
  also has a repository of its own (fathom-novmp, fathom-remill,
  fathom-analysis, fathom-binja).
- rev.ng (`revng.decompile`, 500 MB) is left out; `make-headless.ps1
  -IncludeRevng` adds it from `Fathom_<version>_revng.zip`.
- Tests: `tests/smoke-tools.txt` (`smoke.ps1 -Tools`: NoVmp on the target,
  remill on its entry point), run by the CI.
- Download: 60 MB (the tools: NoVmp 68 MB and remill 27 MB unpacked).

## [1.3.0] - 2026-11-25

Built from [Fathom](https://github.com/EGKrb/Fathom) 1.9.0 (commit `4965e46b`).

- **Emulator**: the package ships Fathom's emulator (`emulator\`, dumpulator):
  the `emu.*` commands of ExtraCmds call a function of the debuggee
  (`emu.call`) or run its thread on (`emu.run`) from a minidump of its state,
  the debuggee not moving; whole programs run with their threads, child
  processes, windows (their images saved), simulated network, registry and
  files, GDI+, OpenGL and Direct3D 9 to 12 (shaders of every stage, ray
  tracing, mesh shaders, work graphs). Needs Python 3.9+ (`emu.setup`).
- Template `emulate-program`: runs the target to its exit in the emulator.
- Tracing (Fathom 1.4): `TraceSetSkip` (calls run untraced) and
  `TraceSetThreads all` (every thread recorded).
- Tests: `tests/smoke-emu.txt` (`smoke.ps1 -Emulator`), run by the CI.

## [1.2.0] - 2026-11-05

Built from [Fathom](https://github.com/EGKrb/Fathom) 1.3.0 (commit `b62a819d`).

- **Faster trace recording**: about 2.5 times faster (x64 with recording:
  4,840 -> 12,300 instructions per second; x32: 1,900 -> 5,000). The engine
  caches the thread contexts while a debug event is handled; `settingset
  Engine, ContextCache, 0` disables it.
- **Thread order of a trace**: the recorder samples every thread (CPU time and
  user-mode registers); `tt.info` and `tt.seek` tell whether the order of the
  instructions of several threads is exact or approximate, the JSON export has
  a `cpu` member and `TraceExport` sets `$result1` / `$result2`.

## [1.1.0] - 2026-11-04

Built from [Fathom](https://github.com/EGKrb/Fathom) 1.2.0 (commit `a4c99038`).

- **Time Travel**: `TraceExport` writes and reads the `.ftt` format (indexed,
  compressed, one timeline per thread, extended registers with `regs=`), and
  ExtraCmds brings the `tt.*` commands (`tt.open`, `tt.seek`, `tt.prev`,
  `tt.regs`, `tt.mem`, `tt.find`, `tt.write`...) on x64 and x32.
- **wineye 1.2.1**: 32-bit code of WoW64 processes unwound, crash-dump
  debugger, MemProcFS and hvlib bundled in `hvkdfusion\` (ntoseye and the
  Dokany installer stay in the full Fathom release).
- `trace-export` template and smoke test: `.ftt` export too.
- CI: downloads only `Fathom_<version>.zip` from the Fathom release (not the
  symbols and sources archives).

## [1.0.0] - 2026-10-29

First release of Fathom headless, the command-line edition of
[Fathom](https://github.com/EGKrb/Fathom) 1.1.0 (commit `ca87bb14`).

- `headless.exe` and the full Fathom debug engine for x64 and x32, without the
  Qt GUI (13 MB instead of 37 MB), including `TraceExport` (JSON, CSV, Tenet,
  Frinet).
- Plugins: pybridge, ExtraCmds (commands-only build on x64), ScyllaHide,
  xAnalyzer; PE-sieve and the HvKdFusion / wineye scripts.
- `run-headless.ps1` launcher (uses the package's own `headless.exe`) and
  twelve script templates; `trace-export` and `run-trace` now also stop when
  the target exits, so short-lived programs can still be exported.
- `tools/make-headless.ps1` builds the package from a Fathom release;
  `tests/smoke.ps1` checks it.

[1.3.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.3.0
[1.2.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.2.0
[1.1.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.1.0
[1.0.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.0.0
