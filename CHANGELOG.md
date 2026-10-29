# Changelog

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

[1.0.0]: https://github.com/EGKrb/fathom-headless/releases/tag/v1.0.0
