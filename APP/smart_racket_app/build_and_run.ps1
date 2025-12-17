$env:PUB_CACHE = "$PSScriptRoot\.pub-cache"
Write-Host "Setting local PUB_CACHE to: $env:PUB_CACHE"
Write-Host "Fetching dependencies to local cache..."
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "Dependencies fetched. Starting Flutter run..."
    flutter run
} else {
    Write-Host "Error fetching dependencies."
}
