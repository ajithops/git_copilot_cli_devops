# Install-GitHubCopilotCLI.ps1
# Install or upgrade the stable GitHub Copilot CLI on Windows.
# Features: Auto-Elevation to Admin & Auto-Installation of PowerShell 7.

$ErrorActionPreference = "Stop"

# --- 1. Check for Administrator Privileges and Elevate if needed ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Administrator privileges are required to install applications. Requesting elevation..." -ForegroundColor Yellow
    $scriptPath =$PSCommandPath
    if (-not $scriptPath) { $scriptPath =$MyInvocation.MyCommand.Path }
    
    # Identify if running from powershell.exe or pwsh.exe
    $currentHost = (Get-Process -Id$PID).Name
    
    # Relaunch the script in a new Administrator window
    Start-Process $currentHost -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "`n=== GitHub Copilot CLI Installer ===" -ForegroundColor Cyan

# --- 2. Check PowerShell version and auto-relaunch in PowerShell 7 (pwsh) ---
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Write-Host "PowerShell 6 or newer is required. Currently running version $($PSVersionTable.PSVersion.Major)." -ForegroundColor Yellow
    
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if (-not $pwsh) {
        Write-Host "PowerShell 7 not found. Installing automatically via WinGet..." -ForegroundColor Cyan
        winget install --id Microsoft.PowerShell --exact --source winget --accept-source-agreements --accept-package-agreements
        
        # Refresh PATH for this session
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
        
        if (-not $pwsh) {
            Write-Error "Could not locate pwsh.exe after installation. Please close this window, open a new terminal, type 'pwsh', and run this script again."
            Read-Host "`nPress Enter to exit..."
            exit 1
        }
    }
    
    Write-Host "Relaunching installer in PowerShell 7..." -ForegroundColor Green
    $scriptPath =$PSCommandPath
    if (-not $scriptPath) { $scriptPath =$MyInvocation.MyCommand.Path }
    
    # Relaunch in pwsh (will inherit Admin rights from this elevated process)
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# --- 3. Check WinGet ---
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $winget) {
    Write-Error @"
WinGet was not found.
Install or update App Installer from the Microsoft Store,
then reopen PowerShell and retry.
"@
    Read-Host "`nPress Enter to exit..."
    exit 1
}

# --- 4. Install / Upgrade GitHub Copilot CLI ---
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
        Write-Error "Installation failed. Check the WinGet output."
        Read-Host "`nPress Enter to exit..."
        exit 1
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

# --- 5. Verify Installation ---
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`n=== Verification ===" -ForegroundColor Cyan

$copilot = Get-Command copilot -ErrorAction SilentlyContinue

if ($copilot) {
    copilot --version
    Write-Host "`nInstallation check completed." -ForegroundColor Green
    Write-Host "Start Copilot CLI using: copilot"
    Write-Host "Authenticate inside the CLI using: copilot auth"
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

# Keeps the new administrator window open so you can read the results
Read-Host "`nPress Enter to exit..."
