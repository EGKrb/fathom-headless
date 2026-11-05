# Fathom headless

[![Licence : GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE) [![Plateforme : Windows](https://img.shields.io/badge/Plateforme-Windows%20x86%2Fx64-0078D6.svg)](#) [![Basé sur x64dbg](https://img.shields.io/badge/bas%C3%A9%20sur-x64dbg-444.svg)](https://github.com/x64dbg/x64dbg) [![Test de fumée](https://github.com/EGKrb/fathom-headless/actions/workflows/smoke.yml/badge.svg)](https://github.com/EGKrb/fathom-headless/actions/workflows/smoke.yml)

**Fathom headless** est l'**édition en ligne de commande** de [Fathom](https://github.com/EGKrb/Fathom), la boîte à outils de rétro-ingénierie construite sur [x64dbg](https://github.com/x64dbg/x64dbg) : `headless.exe` et le moteur de débogage complet **x64 et x32**, sans l'interface Qt. Il débogue des programmes Windows depuis un script, l'entrée standard, des modèles PowerShell ou Python — sur un serveur, dans une VM d'analyse, en CI, en SSH.

🌐 **Site :** <https://egkrb.github.io/fathom-headless/> · 🇬🇧 [English](README.md) · [⬇ Dernière release](https://github.com/EGKrb/fathom-headless/releases/latest)

```
PS> .\x64\headless.exe -cf trace.txt
...
Trace finished after 2000 steps!
Exported 2000 instructions (1 threads, 0 context switches) to C:\work\trace.json
Exported 2000 instructions (1 threads, 0 context switches) to C:\work\trace.log
```

| | Fathom | Fathom headless |
|---|---|---|
| Moteur de débogage, commandes, scripts, expressions | ✅ | ✅ (même build) |
| `TraceExport` → JSON / CSV / Tenet / Frinet / `.ftt` (Time Travel) | ✅ | ✅ |
| Time Travel : commandes `tt.*` (positionnement, retour arrière, recherche, mémoire à un instant) | ✅ | ✅ (commandes ; l'onglet demande l'interface) |
| Enregistrement des traces environ 2,5 fois plus rapide, ordre des threads d'une trace (exact / approximatif, `tt.info`, membre JSON `cpu`) | ✅ | ✅ |
| Plugins : pybridge, ExtraCmds, ScyllaHide, xAnalyzer | ✅ | ✅ (ExtraCmds x64 sans l'onglet graphique) |
| Modèles de scripts et lanceur | ✅ | ✅ |
| Interface Qt (`x64dbg.exe`, `x32dbg.exe`), visionneuse de minidumps | ✅ | — |
| Taille du téléchargement | 72 Mo | **15 Mo** |

---

## Installation

1. Télécharger `fathom-headless_<version>.zip` depuis la [dernière release](https://github.com/EGKrb/fathom-headless/releases/latest).
2. L'extraire dans un dossier **où vous pouvez écrire** (par ex. `C:\Tools\fathom-headless`) : comme x64dbg, le moteur garde ses réglages et bases de données à côté des exécutables, sauf avec `-userdir`.
3. Utiliser `x64\headless.exe` pour les programmes 64 bits et `x32\headless.exe` pour les programmes 32 bits.

```
fathom-headless\
  x64\  x32\            headless.exe, le moteur (x64dbg.dll / x32dbg.dll, TitanEngine...), plugins\
  templates\            scripts x64dbg prêts à l'emploi
  run-headless.ps1      lance un modèle sur une cible
  pybridge\             client Python et exemples (plugin pybridge)
  hvkdfusion\  tools\   scripts HvKdFusion / wineye, PE-sieve
  licenses\             licences d'x64dbg et des composants inclus
```

## Quatre façons de l'utiliser

### 1. Un script

```
// trace.txt
init "C:\echantillons\cible.exe"
StartTraceRecording "C:\travail\trace.trace64"
TraceIntoConditional 0, .2000
StopTraceRecording
TraceExport "C:\travail\trace.trace64", "C:\travail\trace.json"
TraceExport "C:\travail\trace.trace64", "C:\travail\trace.log", tenet
TraceExport "C:\travail\trace.trace64", "C:\travail\trace.ftt", ftt
tt.open "C:\travail\trace.ftt"
tt.seek .1500
tt.regs
```

```powershell
.\x64\headless.exe -cf C:\travail\trace.txt
```

`headless.exe` exécute le script, puis continue de lire des commandes sur l'entrée standard ; il se ferme quand l'entrée standard est fermée (`exit`, ou Ctrl+Z puis Entrée).

### 2. En interactif

```
PS> .\x64\headless.exe
init C:\echantillons\cible.exe
bp kernelbase.CreateFileW
run
run
log "fichier : {utf16@rcx}"
StepOver
exit
```

`init` s'arrête au breakpoint système, le premier `run` au point d'entrée, le second dans `CreateFileW`, où `rcx` contient le premier argument (x64).

Toutes les commandes d'x64dbg fonctionnent : breakpoints (`bp`, `bph`, `bpm`), pas à pas (`StepInto`, `StepOver`, `StepOut`, `run`), mémoire (`savedata`, `findallmem`), traces, `TraceExport`, les commandes des plugins (`pybridge.start`, `.init`, `scylla_hide.enable`, `xanal`...). Les nombres sont en **hexadécimal** par défaut (`.100` = 100 décimal). Voir la [référence des commandes d'x64dbg](https://help.x64dbg.com/en/latest/commands/).

### 3. Les modèles

```powershell
.\run-headless.ps1 -Template api-log -Target C:\Windows\System32\whoami.exe
.\run-headless.ps1 -Template trace-export -Target .\programme32.exe -Arch x32
```

Le lanceur remplace `%TARGET%`, `%MODULE%`, `%OUT%` et `%BITS%`, lance `headless.exe -cf` avec un **dossier de réglages isolé** et écrit tout dans `out\<modèle>-<date>\` (`script.txt`, `headless.log`, fichiers produits). Il affiche le `headless.exe` utilisé : celui du paquet, sinon `-X64dbgDir`, `X64DBG_DIR` ou un x64dbg installé par winget.

| Modèle | Rôle |
|---|---|
| `api-log` | journalise les appels d'API avec leurs arguments, sans pause |
| `hook-apis-extended` | `api-log` élargi (contrôle processus/threads, loader, mémoire, I/O, registre, crypto) |
| `trace-export` | trace jusqu'à 50 000 instructions depuis le point d'entrée (ou jusqu'à la fin du processus) et exporte en JSON, CSV, Tenet et `.ftt` |
| `run-trace` | enregistre jusqu'à 100 000 instructions et exporte en JSON et CSV |
| `dump-module` | sauvegarde le module principal (`.mem`) et un minidump complet au point d'entrée |
| `dump-at-delay` | laisse la cible s'exécuter puis dump le module principal et un minidump (packers qui déballent au démarrage) |
| `hook-unpack` | journalise les API typiques de dépaquetage runtime (`VirtualAlloc`, `VirtualProtect`, `WriteProcessMemory`, `NtMapViewOfSection`, `CryptDecrypt`...) |
| `unpack-dump` | dump la dernière région que `VirtualProtect` passe en PAGE_EXECUTE* |
| `break-on-file` | breakpoint conditionnel sur une ouverture de fichier, puis log, sauvegarde de la pile et minidump |
| `antidebug` | masque le débogueur (`hide` : PEB patché) et journalise les sondes anti-debug |
| `find-pattern` | cherche un motif hexadécimal (avec jokers) ou un littéral ASCII sur toute la carte mémoire |
| `emulate-dump` | émule un `.dmp` avec pybridge et le sert sur 127.0.0.1:27041 |

### 4. Python (pybridge)

```python
import sys
sys.path.insert(0, r"C:\Tools\fathom-headless\pybridge\python")
from x64dbg_bridge import Debugger

with Debugger.launch(r"C:\Tools\fathom-headless") as dbg:     # démarre x64\headless.exe
    dbg.init(r"C:\Windows\System32\whoami.exe")
    dbg.set_breakpoint("kernelbase.CreateFileW")
    if dbg.run(wait=True, timeout=10):
        print(dbg.regs())
```

Voir [pybridge](https://github.com/EGKrb/pybridge) pour toute l'API Python.

## Options de la ligne de commande

| Option | Effet |
|---|---|
| `headless.exe <programme> [arguments]` | commence à déboguer un programme |
| `-cf <script>` | exécute un fichier de script au démarrage |
| `-c "<commande>"` | exécute une commande au démarrage |
| `-pid <n>` (`-p`, `-a`) | s'attache à un processus en cours |
| `-workingDir <dossier>` | dossier de travail du processus lancé |
| `-userdir <dossier>` | dossier des réglages et bases de données (par défaut : à côté de `headless.exe`) |
| `-plugin <chemin>` | charge un plugin supplémentaire (répétable) |
| `-help` | liste les options |

## Remarques

- **ExtraCmds (x64)** est la version sans interface : `.init`, `.save`, `scylla_hide.*`, `hvkd*`, `wineye` et les commandes Time Travel `tt.*` fonctionnent ; les onglets HvKdFusion et Time Travel de Fathom demandent l'interface.
- **Antivirus :** un débogueur écrit dans la mémoire du processus qu'il débogue, ce que la surveillance comportementale peut prendre pour une injection. Pendant les tests, Microsoft Defender a signalé `Behavior:Win32/SuspLummaInj.A` quand le moteur 32 bits déboguait un binaire Windows 32 bits (`C:\Windows\SysWOW64\whoami.exe`) : il a tué le processus débogué et mis `x32\headless.exe` en quarantaine. Le débogage d'autres programmes (et des binaires système 64 bits) n'a pas été affecté. Pour l'analyse de malware, travaillez dans une VM et ajoutez-y une exclusion pour le dossier du paquet.
- À utiliser sur des programmes que vous êtes autorisé à analyser (vos logiciels, échantillons de malware en bac à sable, challenges CTF...).

## Construire le paquet

Le paquet est assemblé à partir d'un build de Fathom par [`tools/make-headless.ps1`](tools/make-headless.ps1) : il garde le moteur, ses DLL et ses plugins, retire l'interface Qt, et ajoute le lanceur, les modèles et la documentation de ce dépôt.

```powershell
# depuis le dossier release d'un build Fathom (tools\make-release.ps1 dans Fathom), avec un ExtraCmds x64 sans Qt
.\tools\make-headless.ps1 -Source C:\src\Fathom\release\release -Version 1.2.0 `
    -ExtraCmdsX64 C:\src\Fathom\extracmds\build-x64-noqt\ExtraCmds.dp64

# ou depuis un Fathom_<version>.zip extrait : -Source est son dossier « release », celui qui contient x64\ et x32\
# (l'ExtraCmds 64 bits est alors retiré)
.\tools\make-headless.ps1 -Source C:\Downloads\Fathom\release
```

WinDbg de Microsoft (`hvkdfusion\windbg64`) n'est jamais copié dans le paquet : il n'est pas redistribuable, et `hvkdfusion.py setup` l'installe. ntoseye et l'installateur Dokany (`hvkdfusion\ntoseye`, `hvkdfusion\dokany`) sont aussi retirés : ils ne servent qu'au débogage noyau via WSL et au montage de la mémoire comme lecteur, et sont fournis avec la release complète de Fathom ; MemProcFS et hvlib (`hvkdfusion\memprocfs`, `hvkdfusion\hvlib`), utilisés par wineye, sont gardés. L'ExtraCmds sans Qt se compile dans Fathom avec `cmake -S extracmds -B extracmds\build-x64-noqt -DCMAKE_DISABLE_FIND_PACKAGE_Qt5=ON ...`.

## Tests

[`tests/smoke.ps1`](tests/smoke.ps1) exécute [`tests/smoke.txt`](tests/smoke.txt) sur [`tests/target.c`](tests/target.c) : démarrage, trace de 2 000 instructions, export JSON, Tenet et `.ftt`, vérification des plugins. GitHub Actions construit le paquet à partir de la dernière release de Fathom et le teste en x64 et x32 à chaque push.

```powershell
.\tests\smoke.ps1 -Package dist\fathom-headless -Target .\target64.exe -Arch x64
```

## Licence

GPL-3.0-or-later — voir [LICENSE](LICENSE). Fathom headless est une distribution modifiée d'[x64dbg](https://github.com/x64dbg/x64dbg) (GPL-3.0) ; les composants inclus gardent leur propre licence (`licenses\`).
