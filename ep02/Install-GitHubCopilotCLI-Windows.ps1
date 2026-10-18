
# Install-GitHubCopilotCLI.ps1
# Install or upgrade the stable GitHub Copilot CLI on Windows.

$ErrorActionPreference = "Stop"

Write-Host "`n=== GitHub Copilot CLI Installer ===" -ForegroundColor Cyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Write-Error "PowerShell 6 or newer is required. Install PowerShell 7 and retry."
    exit 1
}

# Check WinGet
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $winget) {
    Write-Error @"
WinGet was not found.
Install or update App Installer from the Microsoft Store,
then reopen PowerShell and retry.
"@
    exit 1
}

# Install if missing; upgrade if already installed
Write-Host "`nChecking GitHub Copilot CLI..." -ForegroundColor Yellow

$installed = winget list --id GitHub.Copilot --exact `
    --accept-source-agreements 2>$null |
    Out-String

if ($LASTEXITCODE -ne 0 -or
    $installed -notmatch "GitHub\.Copilot") {

    Write-Host "Installing GitHub Copilot CLI..." -ForegroundColor Yellow

    winget install --id GitHub.Copilot --exact `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "Installation failed. Check the WinGet output."
    }
}
else {
    Write-Host "Copilot CLI appears to be installed." -ForegroundColor Green

    Write-Host "Checking for updates..." -ForegroundColor Yellow

    winget upgrade --id GitHub.Copilot --exact `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "WinGet upgrade did not complete successfully. Checking the installed CLI."
    }
}

# Refresh PATH for this session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") +
            ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`n=== Verification ===" -ForegroundColor Cyan

$copilot = Get-Command copilot -ErrorAction SilentlyContinue

if ($copilot) {
    copilot --version
    Write-Host "`nInstallation check completed." -ForegroundColor Green
    Write-Host "Start Copilot CLI using: copilot"
    Write-Host "Authenticate inside the CLI using: /login"
}
else {
    Write-Warning @"
The copilot command is not available in this session.
Close and reopen PowerShell, then run:
    copilot --version
"@
}

Write-Host "`nOfficial documentation:" -ForegroundColor Cyan
Write-Host "https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli"

