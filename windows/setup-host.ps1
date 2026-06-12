param(
  [switch]$InstallRecommended,
  [switch]$InstallOptional,
  [switch]$ExportWinget,
  [string]$WingetExportPath = "$PSScriptRoot\winget-packages.json"
)

$ErrorActionPreference = "Stop"

$RecommendedPackages = @(
  @{
    Id = "Microsoft.WindowsTerminal"
    Reason = "Host terminal with first-class WSL profiles."
  },
  @{
    Id = "Microsoft.PowerToys"
    Reason = "FancyZones, Keyboard Manager, launcher, and other Windows comfort tools."
  }
)

$OptionalPackages = @(
  @{
    Id = "Git.Git"
    Reason = "Windows Git and Git Credential Manager for host-side integration."
  },
  @{
    Id = "Microsoft.VisualStudioCode"
    Reason = "Optional editor and WSL integration, not the primary workflow."
  }
)

function Write-Section($Title) {
  Write-Host ""
  Write-Host "==> $Title" -ForegroundColor Green
}

function Test-Command($Name) {
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-WingetPackage($Package) {
  Write-Host "Checking $($Package.Id) - $($Package.Reason)"

  winget show --id $Package.Id -e | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Package not found or blocked by policy: $($Package.Id)"
    return
  }

  winget install --id $Package.Id -e --accept-source-agreements --accept-package-agreements
}

function Export-WingetPackages($OutputPath) {
  Write-Section "Exporting winget packages"
  Write-Host "Writing host app manifest to $OutputPath"
  winget export -o $OutputPath --accept-source-agreements
}

Write-Section "Windows host setup"
Write-Host "This script handles the Windows host layer only."
Write-Host "Run the Unix development setup from inside WSL with ~/.dotfiles/install.sh."

Write-Section "WSL"
Write-Host "If WSL is not installed, open PowerShell as Administrator and run:"
Write-Host "  wsl --install -d Ubuntu"
Write-Host "After reboot and first Ubuntu launch, clone dotfiles into WSL and run install.sh."
Write-Host ""
Write-Host "Useful WSL maintenance commands:"
Write-Host "  wsl --list --verbose"
Write-Host "  wsl --update"
Write-Host "  wsl --shutdown"
Write-Host ""
Write-Host "Keep active repos inside the WSL filesystem, usually ~/code."
Write-Host "Avoid /mnt/c/... for Linux-heavy development unless work policy requires it."

Write-Section "PowerToys notes"
Write-Host "PowerToys is the closest Windows comfort layer to several Mac utilities:"
Write-Host "  FancyZones       - Rectangle-like window layouts"
Write-Host "  Keyboard Manager - Mac-to-Windows muscle-memory remaps"
Write-Host "  Command Palette  - launcher/command workflow"
Write-Host "  Peek             - quick file previews"
Write-Host "  Text Extractor   - OCR from screen regions"

Write-Section "Dev Drive note"
Write-Host "Dev Drive can help Windows-native repos and package caches, but it needs policy/admin support."
Write-Host "Prefer WSL ~/code for Linux development; consider Dev Drive only for Windows-native work."

Write-Section "Recommended host packages"
$RecommendedPackages | ForEach-Object {
  Write-Host "  $($_.Id) - $($_.Reason)"
}

Write-Section "Optional host packages"
$OptionalPackages | ForEach-Object {
  Write-Host "  $($_.Id) - $($_.Reason)"
}

if (-not (Test-Command winget)) {
  Write-Warning "winget is not available. Use Microsoft Store, company software center, or GitHub releases if approved."
  exit 0
}

if ($InstallRecommended) {
  Write-Section "Installing recommended packages"
  $RecommendedPackages | ForEach-Object { Install-WingetPackage $_ }
}

if ($InstallOptional) {
  Write-Section "Installing optional packages"
  $OptionalPackages | ForEach-Object { Install-WingetPackage $_ }
}

if ($ExportWinget) {
  Export-WingetPackages $WingetExportPath
}

if (-not $InstallRecommended -and -not $InstallOptional -and -not $ExportWinget) {
  Write-Section "Dry plan only"
  Write-Host "Re-run with -InstallRecommended to install Windows Terminal and PowerToys."
  Write-Host "Add -InstallOptional for Windows Git and VS Code."
  Write-Host "Add -ExportWinget to save a host app manifest."
}
