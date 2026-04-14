param(
    [string]$ComposeFile = "docker-compose-db.yml",
    [string]$DbName = "",
    [string]$DbUser = "",
    [string]$DbPassword = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $repoRoot
try {

function Get-ComposeCommand {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try {
            docker compose version *> $null
            return @("docker", "compose")
        }
        catch {
            # Fallback to docker-compose below.
        }
    }

    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        return @("docker-compose")
    }

    throw "Neither 'docker compose' nor 'docker-compose' is available."
}

function Invoke-Compose {
    param([string[]]$ComposeArgs)

    $fullArgs = @()
    if ($script:ComposeCmd.Count -gt 1) {
        $fullArgs += $script:ComposeCmd[1..($script:ComposeCmd.Count - 1)]
    }
    $fullArgs += $ComposeArgs

    & $script:ComposeCmd[0] @fullArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Compose command failed: $($script:ComposeCmd -join ' ') $($ComposeArgs -join ' ')"
    }
}

function Invoke-ComposeCapture {
    param([string[]]$ComposeArgs)

    $fullArgs = @()
    if ($script:ComposeCmd.Count -gt 1) {
        $fullArgs += $script:ComposeCmd[1..($script:ComposeCmd.Count - 1)]
    }
    $fullArgs += $ComposeArgs

    $output = & $script:ComposeCmd[0] @fullArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Compose command failed: $($script:ComposeCmd -join ' ') $($ComposeArgs -join ' ')"
    }

    return ($output | Out-String).Trim()
}

$script:ComposeCmd = Get-ComposeCommand

Write-Host "Using compose command: $($script:ComposeCmd -join ' ')" -ForegroundColor Cyan
Write-Host "Starting postgres + pgadmin from $ComposeFile..." -ForegroundColor Cyan
Invoke-Compose -ComposeArgs @("-f", $ComposeFile, "up", "-d", "postgres", "pgadmin")

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = Invoke-ComposeCapture -ComposeArgs @("-f", $ComposeFile, "exec", "-T", "postgres", "printenv", "POSTGRES_USER")
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = Invoke-ComposeCapture -ComposeArgs @("-f", $ComposeFile, "exec", "-T", "postgres", "printenv", "POSTGRES_DB")
}

if ([string]::IsNullOrWhiteSpace($DbPassword)) {
    $DbPassword = Invoke-ComposeCapture -ComposeArgs @("-f", $ComposeFile, "exec", "-T", "postgres", "printenv", "POSTGRES_PASSWORD")
}

try {
    $portOutput = Invoke-ComposeCapture -ComposeArgs @("-f", $ComposeFile, "port", "postgres", "5432")
}
catch {
    $portOutput = ""
}

$hostPort = "5332"
if ($portOutput -match ':(\d+)\s*$') {
    $hostPort = $Matches[1]
}
elseif (-not [string]::IsNullOrWhiteSpace($env:POSTGRES_PORT)) {
    $hostPort = $env:POSTGRES_PORT
}

$previousConnectionString = $env:ConnectionStrings__DefaultConnection
$env:ConnectionStrings__DefaultConnection = "Host=localhost;Port=$hostPort;Database=$DbName;Username=$DbUser;Password=$DbPassword"

Write-Host "Applying EF Core migrations..." -ForegroundColor Cyan
dotnet ef database update --project src/backend/API/API.csproj --startup-project src/backend/API/API.csproj

if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply EF migrations."
}

$validationQuery = "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('UserProfiles','CustomerAccounts','__EFMigrationsHistory');"
$tableCountRaw = Invoke-ComposeCapture -ComposeArgs @(
    "-f", $ComposeFile,
    "exec", "-T", "postgres",
    "psql", "-U", $DbUser, "-d", $DbName, "-tA", "-c", $validationQuery
)

[int]$tableCount = $tableCountRaw
if ($tableCount -lt 3) {
    throw "Expected 3 tables (UserProfiles, CustomerAccounts, __EFMigrationsHistory), found $tableCount."
}

$dbIdentity = Invoke-ComposeCapture -ComposeArgs @(
    "-f", $ComposeFile,
    "exec", "-T", "postgres",
    "psql", "-U", $DbUser, "-d", $DbName, "-tA", "-c", "SELECT current_user || ':' || current_database();"
)

Write-Host ""
Write-Host "Database sync verification passed." -ForegroundColor Green
Write-Host "Found required tables and verified EF migration history table." -ForegroundColor Green
Write-Host "Connected as: $dbIdentity" -ForegroundColor Green
Write-Host ""
if ([string]::IsNullOrWhiteSpace($env:PGADMIN_PORT)) {
    Write-Host "pgAdmin URL: http://localhost:5050" -ForegroundColor Yellow
}
else {
    Write-Host "pgAdmin URL: http://localhost:$($env:PGADMIN_PORT)" -ForegroundColor Yellow
}
if ([string]::IsNullOrWhiteSpace($env:PGADMIN_DEFAULT_EMAIL)) {
    Write-Host "pgAdmin email: (set PGADMIN_DEFAULT_EMAIL in .env)" -ForegroundColor Yellow
}
else {
    Write-Host "pgAdmin email: $($env:PGADMIN_DEFAULT_EMAIL)" -ForegroundColor Yellow
}
Write-Host "pgAdmin password: (from PGADMIN_DEFAULT_PASSWORD in .env)" -ForegroundColor Yellow

if ($null -eq $previousConnectionString) {
    Remove-Item Env:ConnectionStrings__DefaultConnection -ErrorAction SilentlyContinue
}
else {
    $env:ConnectionStrings__DefaultConnection = $previousConnectionString
}
}
finally {
    Pop-Location
}
