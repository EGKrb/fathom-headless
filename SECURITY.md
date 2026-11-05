# Security Policy

## Supported versions

Fixes go into the latest release only. Each Fathom headless release is built from a Fathom release (see [CHANGELOG.md](CHANGELOG.md)).

| Version | Built from | Supported |
| ------- | ---------- | --------- |
| 1.2.x   | Fathom 1.3.0 | ✅ |
| 1.1.x   | Fathom 1.2.0 | ❌ (update to 1.2.x) |
| 1.0.x   | Fathom 1.1.0 | ❌ (update to 1.2.x) |

## Scope and intended use

**Fathom headless** is the command-line edition of [Fathom](https://github.com/EGKrb/Fathom), a Windows reverse-engineering toolkit **built on [x64dbg](https://github.com/x64dbg/x64dbg)** (GPL-3.0). It is intended for **legitimate, authorized work**: malware analysis in a controlled environment, reverse-engineering of software you have the right to analyze, security research, CTF challenges, CI and debugging your own programs. Use it in accordance with the laws and agreements that apply to you.

It is a debugging and analysis tool, not an exploitation framework. Please do not open issues asking for help attacking systems or software you are not authorized to analyze.

## A note on the debugging surface

Debuggers are powerful by design. Points specific to a headless debugger:

- **Scripts are code.** `headless.exe -cf <script>`, standard input and `run-headless.ps1 -Template <file>` run x64dbg commands with the rights of the user: they can start or attach to processes, read and write their memory, and write files. Only run scripts and templates you trust, and don't pipe untrusted input into `headless.exe`.
- **pybridge** opens a local control server, on `127.0.0.1` only and on demand only (`pybridge.start`, the `emulate-dump` template). While it is running, **any local program that connects to the port can control the debugger**. Stop it when you don't need it, and don't expose the port beyond localhost.
- **HvKdFusion / wineye** (`hvkdfusion\`) read the memory of a whole machine — a live Hyper-V VM or a memory image — with **administrator** rights and through the bundled MemProcFS and hvlib. wineye's server modes (`--serve mcp|dap|gdb`) expose read-only memory over stdio or a local TCP port: keep those bound to localhost.
- **Analysing malware:** the debugged program runs for real. Work in a VM or a sandbox; behaviour monitors can also flag the debugger itself (see the README).

These are inherent properties of the tool, not vulnerabilities.

## Reporting a vulnerability

If you find a security issue **in this repository** (`run-headless.ps1`, the templates, `tools/make-headless.ps1`, the CI) or in **Fathom's own code shipped in the package** (`TraceExport` and the `.ftt` reader, `pybridge`, `ExtraCmds` and the `tt.*` commands, `hvkdfusion/`) — for example memory corruption when reading a crafted trace, a path-handling bug, or a server accepting input in an unsafe way:

1. **Do not** open a public issue describing the exploit.
2. Report it privately through [GitHub's "Report a vulnerability"](https://github.com/EGKrb/fathom-headless/security/advisories/new) (Security tab → Advisories). Issues in Fathom's code can also be reported on [Fathom](https://github.com/EGKrb/Fathom/security/advisories/new).
3. Please include the package version (`CHANGELOG.md`, `fathom-commithash.txt`), a description and reproduction steps.

Vulnerabilities in the **debugger core** or in a **bundled third-party component** should be reported to their upstream projects (x64dbg, ScyllaHide, xAnalyzer, PE-sieve, MemProcFS / LeechCore, LiveCloudKd).

There is no formal SLA for this project, but reports are read and taken seriously.
