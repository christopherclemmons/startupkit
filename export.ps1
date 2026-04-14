# Export script for app
# Creates a zip file excluding build artifacts, dependencies, and personal system data

$excludeDirs = @('node_modules', 'bin', 'obj', 'build', 'postgres_data', 'test-results', 'coverage', '.nyc_output', '.cache', '.parcel-cache', '.next', '.nuget', '.vscode', '.idea', '.terraform', '.git')

function Get-FilesExcludingDirs {
    param($Path, $ExcludeDirs)
    Get-ChildItem -Path $Path -File -Force | ForEach-Object { $_ }
    Get-ChildItem -Path $Path -Directory -Force | Where-Object { $_.Name -notin $ExcludeDirs } | ForEach-Object {
        Get-FilesExcludingDirs -Path $_.FullName -ExcludeDirs $ExcludeDirs
    }
}

$excludeFiles = @('*.user', '*.suo', '*.cache', '*.dll', '*.exe', '*.pdb', '*.log', '*.tmp', '*.temp', '.DS_Store', 'Thumbs.db', 'ehthumbs.db', '*.swp', '*.swo', '*~', '.env', '.env.local', 'appsettings.Development.json', 'appsettings.Production.json', '*.pfx', '*.key', '*.pem', '*.tfstate', '.terraform.lock.hcl', '.dockerignore', '*.tgz', '*.tar.gz', '*.db', '*.sqlite', '*.sqlite3', 'CoverletSourceRootsMapping*', 'app.zip')

$rootPath = (Get-Location).Path

Write-Host "Collecting files to export..." -ForegroundColor Cyan
$files = Get-FilesExcludingDirs -Path . -ExcludeDirs $excludeDirs | Where-Object {
    $excluded = $false
    foreach ($pattern in $excludeFiles) {
        if ($_.Name -like $pattern) {
            $excluded = $true
            break
        }
    }
    -not $excluded
}

Write-Host "Found $($files.Count) files to export" -ForegroundColor Cyan

if ($files.Count -eq 0) {
    Write-Host "No files found to export!" -ForegroundColor Red
    exit
}

Write-Host "Creating app.zip..." -ForegroundColor Cyan

if (Test-Path app.zip) {
    Remove-Item app.zip -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $rootPath 'app.zip'
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)

$addedCount = 0
$ErrorActionPreference = 'SilentlyContinue'
foreach ($file in $files) {
    try {
        $fileFullPath = $file.FullName
        $relativePath = $fileFullPath.Substring($rootPath.Length).TrimStart('\', '/').Replace('\', '/')
        
        if ($relativePath -eq 'app.zip') {
            continue
        }
        
        $entry = $zip.CreateEntry($relativePath)
        $entryStream = $entry.Open()
        $fileStream = [System.IO.File]::OpenRead($fileFullPath)
        $fileStream.CopyTo($entryStream)
        $fileStream.Close()
        $entryStream.Close()
        $addedCount++
    } catch {
        Write-Warning "Failed to add: $($file.FullName) - $($_.Exception.Message)"
    }
}
$ErrorActionPreference = 'Continue'

$zip.Dispose()

Write-Host "Added $addedCount files to zip" -ForegroundColor Cyan
Write-Host "Export complete! Created app.zip" -ForegroundColor Green


