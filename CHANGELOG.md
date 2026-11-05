# Changelog

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

[1.2.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.2.0
[1.1.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.1.0
[1.0.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.0.0
