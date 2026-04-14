# YAML-to-.NET API Scaffolding

Use this flow to generate a new API feature from a YAML spec.

## Script Responsibilities (Crystal Clear)

These files have different jobs:

- `scripts/feature.template.yaml`
  - Input template.
  - You copy this and fill in your feature details.

- `scripts/scaffold-feature.ps1`
  - Windows PowerShell generator.
  - Use this on Windows.
  - Reads YAML and generates/updates API files.

- `scripts/scaffold-feature.sh`
  - Bash entrypoint for macOS/Linux.
  - Use this on macOS/Linux.
  - Calls the Python generator below.

- `scripts/scaffold_feature.py`
  - Python generator used by the Bash script.
  - Cross-platform implementation of the same scaffold behavior.
  - You can run it directly, but most users should use `.ps1` on Windows or `.sh` on macOS/Linux.

Execution map:

- Windows: `feature.yaml` -> `scaffold-feature.ps1` -> generated .NET files
- macOS/Linux: `feature.yaml` -> `scaffold-feature.sh` -> `scaffold_feature.py` -> generated .NET files

## What gets generated

Given a feature name (for example `CustomerAccount`), the script creates:

- `src/backend/API/Models/CustomerAccount.cs` (entity + DTO)
- `src/backend/API/Services/ICustomerAccountService.cs`
- `src/backend/API/Services/CustomerAccountService.cs`
- `src/backend/API/Controllers/CustomerAccountController.cs`

It also updates:

- `src/backend/API/Data/ApplicationDbContext.cs` (`DbSet<>` + model configuration)
- `src/backend/API/Program.cs` (DI registration)

## 1) Create a feature YAML file

Start from `scripts/feature.template.yaml`.

Copy it and edit values for your feature.

If needed, make the Bash script executable once:

```bash
chmod +x ./scripts/scaffold-feature.sh
```

## 2) Dry run first (no files written)

Windows PowerShell:

```powershell
.\scripts\scaffold-feature.ps1 -SpecPath .\scripts\feature.template.yaml -DryRun
```

macOS/Linux Bash:

```bash
./scripts/scaffold-feature.sh --spec-path ./scripts/feature.template.yaml --dry-run
```

## 3) Generate files

Windows PowerShell:

```powershell
.\scripts\scaffold-feature.ps1 -SpecPath .\scripts\feature.template.yaml
```

macOS/Linux Bash:

```bash
./scripts/scaffold-feature.sh --spec-path ./scripts/feature.template.yaml
```

If files already exist and you intentionally want to replace them:

```powershell
.\scripts\scaffold-feature.ps1 -SpecPath .\scripts\feature.template.yaml -Force
```

```bash
./scripts/scaffold-feature.sh --spec-path ./scripts/feature.template.yaml --force
```

## 4) Build and verify

```powershell
dotnet build src/backend/API/API.csproj
```

Then run and inspect Swagger:

```powershell
dotnet run --project src/backend/API/API.csproj
```

- `http://localhost:5000/swagger`

## Notes

- On Windows, `scaffold-feature.ps1` prefers `ConvertFrom-Yaml` when available.
- On Windows, if `ConvertFrom-Yaml` is unavailable, `scaffold-feature.ps1` falls back to Python + PyYAML.
- On macOS/Linux, `scaffold-feature.sh` uses Python (`scaffold_feature.py`) directly.
- Python requirements (for macOS/Linux, and Windows fallback): `python3` + `PyYAML` (`pip3 install pyyaml`).
