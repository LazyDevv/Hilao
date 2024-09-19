# Function to check if PowerShell version is significantly outdated
function Check-AndUpdatePowerShell {
    $minRequiredVersion = [version]'5.1.0'   # Minimum version required for this script to work
    $updateRecommendedVersion = [version]'7.0.0'  # Version to update to if significantly outdated
    $currentVersion = $PSVersionTable.PSVersion

    if ($currentVersion -lt $minRequiredVersion) {
        Write-Host "Your current PowerShell version is $currentVersion. The minimum required version for this script is $minRequiredVersion." -ForegroundColor Yellow
        Write-Host "PowerShell will be automatically updated to ensure compatibility."
        
        # Start the process to update PowerShell
        Start-Process -FilePath "powershell" -ArgumentList "-Command", "& {Start-Process 'msiexec.exe' -ArgumentList '/i https://aka.ms/powershell-$(($env:PROCESSOR_ARCHITECTURE -replace 'AMD64','x64' -replace 'x86','win32')).msi /quiet /norestart' -Wait}" -Verb RunAs
        Write-Host "Please follow the instructions to complete the installation if prompted."
        Write-Host "The system might need a restart to apply changes. Please rerun the script after updating PowerShell."
        Return $false
    } elseif ($currentVersion -lt $updateRecommendedVersion) {
        Write-Host "Your current PowerShell version is $currentVersion. It is recommended to update to a more recent version."
        Write-Host "Updating PowerShell in the background..."
        
        # Update to a recommended version if current version is outdated but still compatible
        Start-Process -FilePath "powershell" -ArgumentList "-Command", "& {Start-Process 'msiexec.exe' -ArgumentList '/i https://aka.ms/powershell-$(($env:PROCESSOR_ARCHITECTURE -replace 'AMD64','x64' -replace 'x86','win32')).msi /quiet /norestart' -Wait}" -Verb RunAs
        Write-Host "PowerShell update is in progress. You may need to restart your system."
    } else {
        Write-Host "Your PowerShell version is up to date."
    }

    Return $true
}

# Check and potentially update PowerShell
if (-not (Check-AndUpdatePowerShell)) {
    Return
}

# Enable TLSv1.2 if it's not already enabled
if (-not ([System.Net.ServicePointManager]::SecurityProtocol.HasFlag([System.Net.SecurityProtocolType]::Tls12))) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}

$DownloadURL = 'https://raw.githubusercontent.com/LazyDevv/Hilao/master/KMS38_Activation.cmd'
$FilePath = "$env:TEMP\KMS38_Activation.cmd"

try {
    Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
} catch {
    Write-Error "Failed to download the file from $DownloadURL. Error: $_"
    Return
}

if (Test-Path $FilePath) {
    try {
        Start-Process $FilePath -Wait
        Remove-Item -LiteralPath $FilePath -Force
    } catch {
        Write-Error "An error occurred while executing or deleting the file. Error: $_"
    }
} else {
    Write-Error "The downloaded file does not exist at $FilePath."
}
