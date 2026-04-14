param(
    [ValidateSet("full", "db")]
    [string]$Mode = "full"
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
            # Fall back to docker-compose below.
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

$script:ComposeCmd = Get-ComposeCommand
$composeFile = if ($Mode -eq "db") { "docker-compose-db.yml" } else { "docker-compose.yml" }

if (-not (Test-Path -LiteralPath ".env")) {
    throw "Missing .env in repository root. Create it first (for example, copy .env.example to .env)."
}

Write-Host "Using compose command: $($script:ComposeCmd -join ' ')" -ForegroundColor Cyan
Write-Host "Reset mode: $Mode ($composeFile)" -ForegroundColor Cyan

Write-Host "Tearing down existing containers and volumes..." -ForegroundColor Yellow
Invoke-Compose -ComposeArgs @("-f", $composeFile, "down", "-v", "--remove-orphans")

Write-Host "Building and starting services from scratch..." -ForegroundColor Yellow
if ($Mode -eq "db") {
    Invoke-Compose -ComposeArgs @("-f", $composeFile, "up", "-d")
}
else {
    Invoke-Compose -ComposeArgs @("-f", $composeFile, "up", "-d", "--build")
}

Write-Host "Current container status:" -ForegroundColor Green
Invoke-Compose -ComposeArgs @("-f", $composeFile, "ps")

Write-Host ""
Write-Host "Reset complete." -ForegroundColor Green
if ($Mode -eq "full") {
    Write-Host "Frontend: http://localhost:3000" -ForegroundColor Green
    Write-Host "Backend Swagger: http://localhost:5000/swagger" -ForegroundColor Green
}
$pgAdminPort = if ([string]::IsNullOrWhiteSpace($env:PGADMIN_PORT)) { "5050" } else { $env:PGADMIN_PORT }
Write-Host "pgAdmin: http://localhost:$pgAdminPort" -ForegroundColor Green
}
finally {
    Pop-Location
}
