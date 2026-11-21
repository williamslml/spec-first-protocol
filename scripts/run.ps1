<#
.SYNOPSIS
  Ejecuta los scripts de spec-first-protocol desde PowerShell en Windows nativo (integrations.sh con bash).
.DESCRIPTION
  No reimplementa nada: busca un `sh` (Git for Windows / Git Bash, o WSL) y le pasa el script
  con las rutas convertidas. Así hay una sola implementación de cada script y las mismas
  garantías (solo lectura, dry-run por defecto, códigos de salida).
  Orden de búsqueda: sh.exe en PATH -> sh.exe junto al git.exe instalado -> rutas habituales
  de Git for Windows -> WSL (wsl.exe). Si no encuentra ninguno, sale con código 4 y explica
  cómo seguir (references/windows.md).
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File <skill>\scripts\run.ps1 discover C:\code\mi-proyecto
.EXAMPLE
  .\run.ps1 verify --run-verify C:\code\mi-proyecto
.EXAMPLE
  .\run.ps1 uninstall C:\code\mi-proyecto          # dry-run
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('discover', 'verify', 'fingerprint', 'uninstall', 'sfp-section', 'integrations')]
  [string]$Script,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $here "$Script.sh"
if (-not $Rest) { $Rest = @() }

function Find-GitSh {
  $c = Get-Command sh.exe -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($git) {
    $root = Split-Path -Parent (Split-Path -Parent $git.Source)
    foreach ($rel in 'bin\sh.exe', 'usr\bin\sh.exe') {
      $p = Join-Path $root $rel
      if (Test-Path $p) { return $p }
    }
  }
  foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA 'Programs'))) {
    if (-not $base) { continue }
    $p = Join-Path $base 'Git\bin\sh.exe'
    if (Test-Path $p) { return $p }
  }
  return $null
}

function Test-PathLike([string]$a) {
  return ($a -match '^[A-Za-z]:[\\/]' -or $a -match '\\' -or $a -match '^\.{1,2}[\\/]')
}

$sh = Find-GitSh
if ($sh) {
  # compatible con Windows PowerShell 5.1 (sin '??')
  $conv = { param($a) if (Test-PathLike $a) { $r = Resolve-Path -LiteralPath $a -ErrorAction SilentlyContinue; $(if ($r) { $r.Path } else { $a }) -replace '\\', '/' } else { $a } }
  $args2 = @($target -replace '\\', '/') + ($Rest | ForEach-Object { & $conv $_ })
  & $sh @args2
  exit $LASTEXITCODE
}

$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($wsl) {
  $toWsl = { param($a) if (Test-PathLike $a) { $r = Resolve-Path -LiteralPath $a -ErrorAction SilentlyContinue; $w = $(if ($r) { $r.Path } else { $a }); (& wsl.exe wslpath -a ($w -replace '\\', '/')).Trim() } else { $a } }
  # integrations.sh es Bash (set -o pipefail, arrays): en WSL `sh` suele ser dash.
  $shell = $(if ($Script -eq 'integrations') { 'bash' } else { 'sh' })
  $args2 = @($shell, (& $toWsl $target)) + ($Rest | ForEach-Object { & $toWsl $_ })
  & wsl.exe @args2
  exit $LASTEXITCODE
}

Write-Host 'No se encontró sh (Git for Windows / Git Bash) ni WSL.'
Write-Host 'Opciones: instalar Git for Windows (incluye sh), activar WSL, o hacer las comprobaciones a mano'
Write-Host 'con la checklist de references/scenarios.md y decir en el plan que no se usó el script.'
Write-Host 'Detalle: references/windows.md'
exit 4
