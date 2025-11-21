# Release Script for Flutter App
# This script builds the release APK and copies it to the project root

Write-Host "Building release APK..."
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Copying APK to project root..."
    Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "blinkscrew.apk"
    if ($?) {
        Write-Host "APK copied successfully: blinkscrew.apk"
    } else {
        Write-Host "Failed to copy APK!"
        exit 1
    }
} else {
    Write-Host "Build failed!"
    exit 1
}