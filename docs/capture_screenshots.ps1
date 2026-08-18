# Capture Lips Offline screenshots for graduation documentation.
# Usage: connect Android phone via USB, unlock screen, close phone calls, then run:
#   powershell -ExecutionPolicy Bypass -File docs\capture_screenshots.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Error "adb not found at $adb. Install Android SDK platform-tools."
}

$dev = (& $adb devices | Select-String "device$" | Select-Object -First 1).ToString().Split("`t")[0]
if (-not $dev) { Write-Error "No Android device connected." }

$pkg = "com.example.lips_offline"
$out = Join-Path $PSScriptRoot "screenshots"
New-Item -ItemType Directory -Path $out -Force | Out-Null

function Shot($name) {
    $path = Join-Path $out $name
    flutter screenshot -d $dev -o $path | Out-Null
    Write-Host "Saved $name ($((Get-Item $path).Length) bytes)"
}

Write-Host "Using device: $dev"
& $adb shell input keyevent KEYCODE_ENDCALL 2>$null
& $adb shell am force-stop $pkg
Start-Sleep -Seconds 1
& $adb shell am start -n "$pkg/.MainActivity" | Out-Null
Start-Sleep -Milliseconds 900
Shot "01_splash.png"
Start-Sleep -Seconds 2
Shot "02_onboarding_lipsing.png"
& $adb shell input tap 540 2100
Start-Sleep -Seconds 1
Shot "03_onboarding_letters.png"
& $adb shell input tap 540 2100
Start-Sleep -Seconds 1
Shot "04_onboarding_camera.png"
& $adb shell input tap 540 2100
Start-Sleep -Seconds 6
Shot "05_home_idle.png"
& $adb shell input tap 980 120
Start-Sleep -Seconds 2
Shot "09_settings.png"
& $adb shell input keyevent 4
Start-Sleep -Seconds 2
Shot "06_home_lipsing.png"
Shot "07_home_letter.png"
& $adb shell input tap 200 1700
Start-Sleep -Seconds 1
Shot "08_home_matched.png"
Write-Host "Done. Check docs/screenshots/"
