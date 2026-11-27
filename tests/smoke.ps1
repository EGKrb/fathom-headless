<#
.SYNOPSIS
Runs tests\smoke.txt with a Fathom headless package and checks the exported trace.

.EXAMPLE
.\tests\smoke.ps1 -Package dist\fathom-headless -Target .\target64.exe -Arch x64
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $Package,

    [Parameter(Mandatory = $true)]
    [string] $Target,

    [ValidateSet('x64', 'x32')]
    [string] $Arch = 'x64',

    [int] $TimeoutSeconds = 180,

    # also run the emulator (tests\smoke-emu.txt): needs ExtraCmds and Python with the emulator's packages
    [switch] $Emulator,

    # also run NoVmp and remill (tests\smoke-tools.txt): needs ExtraCmds
    [switch] $Tools
)

$ErrorActionPreference = 'Stop'
$Package = (Resolve-Path $Package).Path
$out = Join-Path ([IO.Path]::GetTempPath()) ("fathom-headless-smoke-$Arch-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
& (Join-Path $Package 'run-headless.ps1') -Template (Join-Path $PSScriptRoot 'smoke.txt') -Target $Target -Arch $Arch -OutDir $out -TimeoutSeconds $TimeoutSeconds
$log = Get-Content -Raw (Join-Path $out 'headless.log')
if ($LASTEXITCODE -ne 0 -or $log -notmatch '\[template\] done') { throw "headless run failed, see $out\headless.log" }
foreach ($plugin in 'pybridge', 'ExtraCmds') {
    if ($log -notmatch "\[pluginload\] $plugin") { Write-Warning "plugin $plugin was not loaded" }
}
$json = Get-Content -Raw (Join-Path $out 'trace.json') | ConvertFrom-Json
$count = $json.instructions.Count
if ($count -lt 100) { throw "trace.json has only $count instructions" }
$lines = (Get-Content (Join-Path $out 'trace.log')).Count
if ($lines -ne $count) { throw "trace.log has $lines lines, trace.json $count instructions" }
# .ftt (Time Travel): header "FTT1", index footer "FTTX" in the last 16 bytes
$ftt = [IO.File]::ReadAllBytes((Join-Path $out 'trace.ftt'))
$ascii = [Text.Encoding]::ASCII
if ($ftt.Length -lt 32 -or $ascii.GetString($ftt, 0, 4) -ne 'FTT1' -or $ascii.GetString($ftt, $ftt.Length - 8, 4) -ne 'FTTX') { throw 'trace.ftt is not a .ftt file' }
"smoke $Arch OK: $count instructions exported (JSON + Tenet + .ftt), output in $out"
$extraCmds = $log -match '\[pluginload\] ExtraCmds'
if (($Emulator -or $Tools) -and -not $extraCmds) { Write-Warning "emulator and tools: ExtraCmds is not in the $Arch package, skipped"; return }
if ($Emulator) {
    $emu = Join-Path ([IO.Path]::GetTempPath()) ("fathom-headless-emu-$Arch-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    & (Join-Path $Package 'run-headless.ps1') -Template (Join-Path $PSScriptRoot 'smoke-emu.txt') -Target $Target -Arch $Arch -OutDir $emu -TimeoutSeconds $TimeoutSeconds
    $log = Get-Content -Raw (Join-Path $emu 'headless.log')
    if ($log -notmatch '\[emu\] lstrlenA 5\b') { throw "emu.call failed, see $emu\headless.log" }
    if ($log -notmatch '\[emu\] exit (\d+)') { throw "emu.run did not run the target to its exit, see $emu\headless.log" }
    "smoke $Arch emulator OK: lstrlenA(hello) = 5 in the emulator, the target ran to its exit (code $($Matches[1]))"
}
if ($Tools) {
    $toolsOut = Join-Path ([IO.Path]::GetTempPath()) ("fathom-headless-tools-$Arch-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    & (Join-Path $Package 'run-headless.ps1') -Template (Join-Path $PSScriptRoot 'smoke-tools.txt') -Target $Target -Arch $Arch -OutDir $toolsOut -TimeoutSeconds $TimeoutSeconds
    $log = Get-Content -Raw (Join-Path $toolsOut 'headless.log')
    if ($log -notmatch '\[tools\] novmp 0\b') { throw "novmp did not run NoVmp on the target, see $toolsOut\headless.log" }
    if ($log -notmatch '\[tools\] remill (\d+)' -or [int]$Matches[1] -lt 20) { throw "remill.lift did not lift the entry point, see $toolsOut\headless.log" }
    "smoke $Arch tools OK: NoVmp ran on the target (no virtual machine), remill lifted the entry point ($($Matches[1]) lines of LLVM IR)"
}
