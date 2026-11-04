<#
.SYNOPSIS
Builds the Fathom headless package (command-line debugger, no GUI) from a Fathom release.

.DESCRIPTION
Takes the "release" folder of a Fathom build (or of an extracted Fathom_<version>.zip) and keeps
only what headless.exe needs: the debug engine, its DLLs and plugins, for x64 and x32. The Qt
GUI (x64dbg.exe / x32dbg.exe, x64gui.dll / x32gui.dll, Qt5*.dll and the Qt plugin folders) and
the Qt minidump viewer are left out. The launcher, the templates and the docs of this
repository are added.

The 64-bit ExtraCmds plugin of a Fathom release is built with Qt (HvKdFusion GUI tab) and does
not load without the Qt DLLs: pass a commands-only build with -ExtraCmdsX64 (configure
extracmds with -DCMAKE_DISABLE_FIND_PACKAGE_Qt5=ON), otherwise it is left out with a warning.

Output: <OutDir>\fathom-headless_<Version>.zip (folder fathom-headless\) and SHA256SUMS.txt.

.EXAMPLE
.\tools\make-headless.ps1 -Source C:\Fathom\release -Version 1.0.0

.EXAMPLE
.\tools\make-headless.ps1 -Source C:\src\Fathom\release\release -ExtraCmdsX64 C:\src\Fathom\extracmds\build-x64-noqt\ExtraCmds.dp64
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $Source,

    [string] $Version = '1.0.0',

    [string] $ExtraCmdsX64,

    [string] $OutDir
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $OutDir) { $OutDir = Join-Path $root 'dist' }
$Source = (Resolve-Path $Source).Path
foreach ($file in 'x64\headless.exe', 'x64\x64dbg.dll', 'x32\headless.exe', 'x32\x32dbg.dll') {
    if (-not (Test-Path (Join-Path $Source $file))) { throw "missing $file in $Source (pass the release folder of Fathom)" }
}

# GUI-only files: the Qt front-end and everything it loads
$excludeFiles = 'x64dbg.exe', 'x32dbg.exe', 'x64gui.dll', 'x32gui.dll', 'minidump.exe', 'Qt5*.dll', 'd3dcompiler_*.dll', 'libEGL.dll', 'libGLESV2.dll', 'opengl32sw.dll'
$excludeDirs = 'iconengines', 'imageformats', 'platforms', 'styles'

$stage = Join-Path $OutDir 'fathom-headless'
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null

function Test-LinksQt([string] $Path) {
    # The import table stores DLL names as ASCII: a Qt-linked plugin contains "Qt5Core.dll"
    $bytes = [IO.File]::ReadAllBytes($Path)
    $text = [Text.Encoding]::ASCII.GetString($bytes)
    return $text.Contains('Qt5Core.dll')
}

foreach ($arch in 'x64', 'x32') {
    $from = Join-Path $Source $arch
    $to = Join-Path $stage $arch
    New-Item -ItemType Directory -Force $to | Out-Null
    foreach ($item in Get-ChildItem $from) {
        if ($item.PSIsContainer) {
            if ($excludeDirs -contains $item.Name) { continue }
        }
        elseif ($excludeFiles | Where-Object { $item.Name -like $_ }) { continue }
        elseif ($item.Extension -in '.pdb', '.lib', '.exp') { continue }
        Copy-Item -Recurse $item.FullName $to
    }
    # A plugin that imports Qt would fail to load in headless.exe
    foreach ($plugin in Get-ChildItem (Join-Path $to 'plugins') -File -Include *.dp64, *.dp32 -Recurse) {
        if (-not (Test-LinksQt $plugin.FullName)) { continue }
        if ($arch -eq 'x64' -and $plugin.Name -eq 'ExtraCmds.dp64' -and $ExtraCmdsX64) {
            Copy-Item -Force $ExtraCmdsX64 $plugin.FullName
            if (Test-LinksQt $plugin.FullName) { throw "-ExtraCmdsX64 is a Qt build: $ExtraCmdsX64" }
            Write-Host "ExtraCmds.dp64: replaced by the commands-only build"
        }
        else {
            Remove-Item $plugin.FullName
            Write-Warning "$arch\plugins\$($plugin.Name) imports Qt and was left out (see -ExtraCmdsX64)"
        }
    }
}

# Databases read by the engine, and the Fathom extras that work without a GUI
foreach ($name in 'errordb.txt', 'exceptiondb.txt', 'mnemdb.json', 'ntstatusdb.txt', 'winconstants.txt') {
    $file = Join-Path $Source $name
    if (Test-Path $file) { Copy-Item $file $stage }
}
foreach ($name in 'pybridge', 'hvkdfusion', 'tools', 'licenses') {
    $dir = Join-Path $Source $name
    if (Test-Path $dir) { Copy-Item -Recurse $dir $stage }
}
# WinDbg is Microsoft software that may not be redistributed: HvKdFusion installs it with `setup`
$windbg = Join-Path $stage 'hvkdfusion\windbg64'
if (Test-Path $windbg) {
    Remove-Item -Recurse -Force $windbg
    Write-Warning 'hvkdfusion\windbg64 (Microsoft WinDbg) was left out: it is not redistributable'
}
# Not needed to debug from the command line, and 50 MB together: ntoseye (Linux build run through
# WSL) and the Dokany installer (kernel driver, only to mount memory as a drive). `setup` uses
# installed copies, or says where to get them.
foreach ($name in 'ntoseye', 'dokany') {
    $dir = Join-Path $stage "hvkdfusion\$name"
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir
        Write-Host "hvkdfusion\${name}: left out (full Fathom release only)"
    }
}
foreach ($name in 'config.json', '__pycache__') {
    $item = Join-Path $stage "hvkdfusion\$name"
    if (Test-Path $item) { Remove-Item -Recurse -Force $item }
}
$commit = Join-Path (Split-Path $Source) 'commithash.txt'
if (Test-Path $commit) { Copy-Item $commit (Join-Path $stage 'fathom-commithash.txt') }

# This repository: launcher, templates, docs
Copy-Item (Join-Path $root 'run-headless.ps1') $stage
Copy-Item -Recurse (Join-Path $root 'templates') $stage
foreach ($name in 'README.md', 'README.fr.md', 'LICENSE', 'CHANGELOG.md') {
    Copy-Item (Join-Path $root $name) $stage
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$zip = Join-Path $OutDir "fathom-headless_$Version.zip"
Remove-Item -Force $zip -ErrorAction SilentlyContinue
Compress-Archive -CompressionLevel Optimal -Path $stage -DestinationPath $zip
$hash = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLowerInvariant()
# LF line endings so that `sha256sum -c SHA256SUMS.txt` works
[IO.File]::WriteAllText((Join-Path $OutDir 'SHA256SUMS.txt'), "$hash  $(Split-Path -Leaf $zip)`n", (New-Object Text.ASCIIEncoding))
$size = (Get-ChildItem -Recurse -File $stage | Measure-Object Length -Sum).Sum / 1MB
"{0}  {1:N1} MB zipped, {2:N1} MB unpacked  sha256 {3}" -f (Split-Path -Leaf $zip), ((Get-Item $zip).Length / 1MB), $size, $hash
