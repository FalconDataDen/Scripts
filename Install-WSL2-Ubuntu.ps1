# Function to check if running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Relaunch the script with elevated privileges if not running as admin
if (-not (Test-Admin)) {
    Write-Host "Running with insufficient privileges. Relaunching as administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Install-Wsl2KernelUpdate {
    $wslKernelUpdateUrl = "https://aka.ms/wsl2kernel"
    $tempFolderPath = "C:\Temp"
    $tempFilePath = "$tempFolderPath\wsl2kernel_update.msi"

    # Create the C:\Temp folder if it does not exist
    if (-not (Test-Path $tempFolderPath)) {
        Write-Host "Creating C:\Temp folder..." -ForegroundColor Yellow
        New-Item -Path $tempFolderPath -ItemType Directory | Out-Null
    }

    # Download the WSL2 kernel update
    Write-Host "Downloading WSL2 kernel update..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $wslKernelUpdateUrl -OutFile $tempFilePath

    # Install the downloaded kernel update
    Write-Host "Installing WSL2 kernel update..." -ForegroundColor Yellow
    Start-Process -FilePath msiexec.exe -ArgumentList "/i $tempFilePath /quiet /norestart" -Wait

    # Check if installation was successful (you may need to adjust this depending on your environment)
    $success = $LastExitCode -eq 0
    if ($success) {
        # Cleanup the downloaded file
        Remove-Item -Path $tempFilePath -Force
        Write-Host "WSL2 kernel update installed successfully." -ForegroundColor Green
    } else {
        Write-Host "WSL2 kernel update installation failed. Please check the logs." -ForegroundColor Red
    }
}

# Prompt the user for action
Write-Host "****** Choose an action by entering the corresponding number: ******" -ForegroundColor White -BackgroundColor Red
Write-Host "1: Install Windows features (WSL and Virtual Machine Platform)" -ForegroundColor Cyan
Write-Host "2: Install WSL2 and Ubuntu 24.04" -ForegroundColor Cyan

$choice = Read-Host "Enter your choice:"

switch ($choice) {
    '1' {
        # Part 1: Install Windows Features (WSL and Virtual Machine Platform)

        # Enable WSL and Virtual Machine Platform features
        Write-Host "Enabling Windows Subsystem for Linux (WSL) and Virtual Machine Platform..." -ForegroundColor Green
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

        # Reboot the system to apply changes
        Write-Host "Windows Features have been enabled. Restarting the system to complete the installation..." -ForegroundColor Green
        Restart-Computer -Force
    }
    '2' {
        # Part 2: Install WSL2 and Ubuntu

        # Download and install the latest WSL2 kernel update
        Write-Host "Downloading and installing the latest WSL2 kernel update..." -ForegroundColor Green
        Install-Wsl2KernelUpdate

        # Set WSL2 as the default version
        Write-Host "Setting WSL2 as the default version..." -ForegroundColor Green
        wsl --set-default-version 2

        # Install Ubuntu distribution
        Write-Host "Installing Ubuntu 24.04 distribution..." -ForegroundColor Green
        wsl --install -d Ubuntu-24.04

        Write-Host "WSL2 and Ubuntu 24.04 installation completed successfully." -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice. Please enter '1' to install Windows features or '2' to install WSL2 and Ubuntu." -ForegroundColor Red
        Write-Host "Try again by restarting the script and choosing a valid option." -ForegroundColor Red
    }
}

# Take a pause before script terminiates
Pause
