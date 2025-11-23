# Release Script for Flutter App
# This script builds the release APK and copies it to the project root

Write-Host "Building release APK..."
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Copying APK to project root..."
    Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "binkscrew.apk"
    if ($?) {
        Write-Host "APK copied successfully: binkscrew.apk"
        
        # Extract version from pubspec.yaml
        $pubspecContent = Get-Content "pubspec.yaml"
        $versionLine = $pubspecContent | Where-Object { $_ -match '^version:' }
        if ($versionLine) {
            $version = ($versionLine -split ':')[1].Trim()
            Write-Host "Version: $version"
            
            # Create version.json
            $versionJson = @{
                version = $version
            } | ConvertTo-Json
            $versionJson | Out-File -FilePath "version.json" -Encoding UTF8
            Write-Host "version.json created successfully."
        } else {
            Write-Host "Version not found in pubspec.yaml!"
        }
    } else {
        Write-Host "Failed to copy APK!"
        exit 1
    }
} else {
    Write-Host "Build failed!"
    exit 1
}