param(
    [Parameter(Mandatory = $true)]
    [string]$SpecPath,

    [string]$ApiRoot = "src/backend/API",

    [switch]$DryRun,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PascalCase {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Value cannot be empty when converting to PascalCase."
    }

    $parts = @($Value -split '[^A-Za-z0-9]+' | Where-Object { $_ -ne "" })
    if ($parts.Count -eq 0) {
        return $Value
    }

    ($parts | ForEach-Object {
        if ($_.Length -eq 1) {
            $_.ToUpperInvariant()
        }
        else {
            $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
        }
    }) -join ''
}

function Get-CamelCase {
    param([string]$Value)
    $pascal = Get-PascalCase $Value
    if ($pascal.Length -eq 1) {
        return $pascal.ToLowerInvariant()
    }
    return $pascal.Substring(0, 1).ToLowerInvariant() + $pascal.Substring(1)
}

function Get-PluralName {
    param([string]$Singular)

    if ($Singular -match '[^aeiou]y$') {
        return ($Singular.Substring(0, $Singular.Length - 1) + "ies")
    }

    if ($Singular -match '(s|x|z|ch|sh)$') {
        return "$Singular" + "es"
    }

    return "$Singular" + "s"
}

function Get-CSharpType {
    param(
        [string]$YamlType,
        [bool]$Required
    )

    $safeYamlType = if ($null -eq $YamlType) { "" } else { "$YamlType" }
    $normalized = $safeYamlType.Trim().ToLowerInvariant()
    switch ($normalized) {
        "string" { return "string" + ($(if ($Required) { "" } else { "?" })) }
        "int" { return "int" + ($(if ($Required) { "" } else { "?" })) }
        "integer" { return "int" + ($(if ($Required) { "" } else { "?" })) }
        "long" { return "long" + ($(if ($Required) { "" } else { "?" })) }
        "guid" { return "Guid" + ($(if ($Required) { "" } else { "?" })) }
        "datetime" { return "DateTime" + ($(if ($Required) { "" } else { "?" })) }
        "bool" { return "bool" + ($(if ($Required) { "" } else { "?" })) }
        "boolean" { return "bool" + ($(if ($Required) { "" } else { "?" })) }
        "decimal" { return "decimal" + ($(if ($Required) { "" } else { "?" })) }
        "double" { return "double" + ($(if ($Required) { "" } else { "?" })) }
        "float" { return "float" + ($(if ($Required) { "" } else { "?" })) }
        default { throw "Unsupported field type '$YamlType'. Add it to Get-CSharpType." }
    }
}

function Parse-YamlFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Spec file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw

    if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        return ($raw | ConvertFrom-Yaml)
    }

    if (Get-Command python -ErrorAction SilentlyContinue) {
        $python = @'
import json
import pathlib
import sys
import yaml

path = pathlib.Path(sys.argv[1])
data = yaml.safe_load(path.read_text(encoding="utf-8"))
print(json.dumps(data))
'@
        $json = $python | python - $Path
        if ([string]::IsNullOrWhiteSpace($json)) {
            throw "Failed to parse YAML via Python."
        }
        return ($json | ConvertFrom-Json)
    }

    throw "YAML parsing is unavailable. Install PowerShell 7 (ConvertFrom-Yaml) or Python with PyYAML."
}

function Get-OptionalValue {
    param(
        $Object,
        [string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        return $Default
    }

    return $prop.Value
}

function Add-IndentedBlock {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [int]$InsertAt,
        [string[]]$Block
    )
    $Lines.InsertRange($InsertAt, [string[]]$Block)
}

function Write-FileSafe {
    param(
        [string]$Path,
        [string]$Content,
        [switch]$AllowOverwrite
    )

    if ((Test-Path -LiteralPath $Path) -and -not $AllowOverwrite) {
        throw "File already exists: $Path. Use -Force to overwrite."
    }

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

$resolvedApiRoot = Resolve-Path -LiteralPath $ApiRoot
$spec = Parse-YamlFile -Path $SpecPath

$feature = $spec.feature
if ($null -eq $feature) {
    throw "Spec must include a top-level 'feature' object."
}

$featureName = Get-PascalCase $feature.name
$entityName = if (Get-OptionalValue -Object $feature -Name "entity_name") { Get-PascalCase (Get-OptionalValue -Object $feature -Name "entity_name") } else { $featureName }
$dtoName = if (Get-OptionalValue -Object $feature -Name "dto_name") { Get-PascalCase (Get-OptionalValue -Object $feature -Name "dto_name") } else { "$entityName" + "Dto" }
$serviceName = if (Get-OptionalValue -Object $feature -Name "service_name") { Get-PascalCase (Get-OptionalValue -Object $feature -Name "service_name") } else { "$featureName" + "Service" }
$interfaceName = if (Get-OptionalValue -Object $feature -Name "interface_name") { Get-PascalCase (Get-OptionalValue -Object $feature -Name "interface_name") } else { "I$serviceName" }
$controllerName = if (Get-OptionalValue -Object $feature -Name "controller_name") { Get-PascalCase (Get-OptionalValue -Object $feature -Name "controller_name") } else { "$featureName" + "Controller" }
$dbSetName = if (Get-OptionalValue -Object $feature -Name "dbset_name") { Get-PascalCase (Get-OptionalValue -Object $feature -Name "dbset_name") } else { Get-PluralName $entityName }
$routeSegment = if (Get-OptionalValue -Object $feature -Name "route_segment") { "$((Get-OptionalValue -Object $feature -Name "route_segment"))".Trim() } else { $featureName.ToLowerInvariant() }
$timestampsValue = Get-OptionalValue -Object $feature -Name "timestamps"
$useTimestamps = if ($null -eq $timestampsValue) { $true } else { [bool]$timestampsValue }

$keySpec = Get-OptionalValue -Object $feature -Name "key"
if ($null -eq $keySpec) {
    throw "Spec must include feature.key with name/type."
}
$keyName = Get-PascalCase $keySpec.name
$keyParam = Get-CamelCase $keyName
$keyRequiredValue = Get-OptionalValue -Object $keySpec -Name "required"
$keyRequired = if ($null -eq $keyRequiredValue) { $true } else { [bool]$keyRequiredValue }
$keyType = Get-CSharpType -YamlType $keySpec.type -Required $keyRequired

$fieldSpecs = @()
$rawFields = Get-OptionalValue -Object $feature -Name "fields" -Default @()
if ($rawFields) {
    foreach ($field in @($rawFields)) {
        $fieldRequiredValue = Get-OptionalValue -Object $field -Name "required"
        $required = if ($null -eq $fieldRequiredValue) { $false } else { [bool]$fieldRequiredValue }
        $fieldMaxLengthValue = Get-OptionalValue -Object $field -Name "max_length"
        $fieldSpecs += [PSCustomObject]@{
            Name = Get-PascalCase $field.name
            ParamName = Get-CamelCase $field.name
            Type = Get-CSharpType -YamlType $field.type -Required $required
            Required = $required
            MaxLength = if ($null -eq $fieldMaxLengthValue) { $null } else { [int]$fieldMaxLengthValue }
            IsString = ("$($field.type)".Trim().ToLowerInvariant() -eq "string")
        }
    }
}

$modelPath = Join-Path $resolvedApiRoot "Models/$entityName.cs"
$interfacePath = Join-Path $resolvedApiRoot "Services/$interfaceName.cs"
$servicePath = Join-Path $resolvedApiRoot "Services/$serviceName.cs"
$controllerPath = Join-Path $resolvedApiRoot "Controllers/$controllerName.cs"
$dbContextPath = Join-Path $resolvedApiRoot "Data/ApplicationDbContext.cs"
$programPath = Join-Path $resolvedApiRoot "Program.cs"

$modelLines = New-Object System.Collections.Generic.List[string]
$modelLines.Add("using System.ComponentModel.DataAnnotations;")
$modelLines.Add("")
$modelLines.Add("namespace API.Models;")
$modelLines.Add("")
$modelLines.Add("public class $entityName")
$modelLines.Add("{")
$modelLines.Add("    public $keyType $keyName { get; set; }")

foreach ($field in $fieldSpecs) {
    $modelLines.Add("")
    if ($field.MaxLength) {
        $modelLines.Add("    [MaxLength($($field.MaxLength))]")
    }
    if ($field.Required) {
        $modelLines.Add("    [Required]")
    }
    if ($field.IsString -and $field.Required) {
        $modelLines.Add("    public $($field.Type) $($field.Name) { get; set; } = string.Empty;")
    }
    else {
        $modelLines.Add("    public $($field.Type) $($field.Name) { get; set; }")
    }
}

if ($useTimestamps) {
    $modelLines.Add("")
    $modelLines.Add("    public DateTime CreatedAt { get; set; }")
    $modelLines.Add("")
    $modelLines.Add("    public DateTime UpdatedAt { get; set; }")
}

$modelLines.Add("}")
$modelLines.Add("")
$modelLines.Add("public class $dtoName")
$modelLines.Add("{")
$modelLines.Add("    [Required]")
$modelLines.Add("    public $keyType $keyName { get; set; }")

foreach ($field in $fieldSpecs) {
    $modelLines.Add("")
    if ($field.MaxLength) {
        $modelLines.Add("    [MaxLength($($field.MaxLength))]")
    }
    if ($field.Required) {
        $modelLines.Add("    [Required]")
    }
    if ($field.IsString -and $field.Required) {
        $modelLines.Add("    public $($field.Type) $($field.Name) { get; set; } = string.Empty;")
    }
    else {
        $modelLines.Add("    public $($field.Type) $($field.Name) { get; set; }")
    }
}

$modelLines.Add("}")

$interfaceContent = @"
using API.Models;

namespace API.Services;

public interface $interfaceName
{
    Task<${dtoName}?> Get${featureName}Async($keyType $keyParam);
    Task<$dtoName> CreateOrUpdate${featureName}Async($dtoName $($featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1))Dto);
}
"@

$entityToDtoAssignments = @("            $keyName = entity.$keyName")
foreach ($field in $fieldSpecs) {
    $entityToDtoAssignments += "            $($field.Name) = entity.$($field.Name)"
}

$dtoToEntityAssignments = @("                $keyName = $($featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1))Dto.$keyName")
foreach ($field in $fieldSpecs) {
    $dtoToEntityAssignments += "                $($field.Name) = $($featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1))Dto.$($field.Name)"
}

$updateAssignments = @()
foreach ($field in $fieldSpecs) {
    $updateAssignments += "            entity.$($field.Name) = $($featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1))Dto.$($field.Name);"
}

$timestampCreate = if ($useTimestamps) {
@"
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
"@
} else { "" }

$timestampUpdate = if ($useTimestamps) {
@"
            entity.UpdatedAt = DateTime.UtcNow;
"@
} else { "" }

$serviceContent = @"
using Microsoft.EntityFrameworkCore;
using API.Data;
using API.Models;

namespace API.Services;

public class $serviceName : $interfaceName
{
    private readonly ApplicationDbContext _context;

    public $serviceName(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<${dtoName}?> Get${featureName}Async($keyType $keyParam)
    {
        var entity = await _context.$dbSetName
            .FirstOrDefaultAsync(e => e.$keyName == $keyParam);

        if (entity == null)
        {
            return null;
        }

        return new $dtoName
        {
$($entityToDtoAssignments -join ",`r`n")
        };
    }

    public async Task<$dtoName> CreateOrUpdate${featureName}Async($dtoName $($featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1))Dto)
    {
        var entity = await _context.$dbSetName
            .FirstOrDefaultAsync(e => e.$keyName == $($featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1))Dto.$keyName);

        if (entity == null)
        {
            entity = new $entityName
            {
$($dtoToEntityAssignments -join ",`r`n")$(if ($useTimestamps) { ",`r`n$timestampCreate" } else { "" })
            };
            _context.$dbSetName.Add(entity);
        }
        else
        {
$($updateAssignments -join "`r`n")
$timestampUpdate
            _context.$dbSetName.Update(entity);
        }

        await _context.SaveChangesAsync();

        return new $dtoName
        {
$($entityToDtoAssignments -join ",`r`n")
        };
    }
}
"@

$controllerDtoVar = $featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1) + "Dto"
$serviceField = "_" + $featureName.Substring(0,1).ToLowerInvariant() + $featureName.Substring(1) + "Service"

$controllerContent = @"
using Microsoft.AspNetCore.Mvc;
using API.Models;
using API.Services;

namespace API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class $controllerName : ControllerBase
{
    private readonly $interfaceName $serviceField;

    public $controllerName($interfaceName $serviceField)
    {
        this.$serviceField = $serviceField;
    }

    /// <summary>
    /// Gets a single $routeSegment by $keyParam.
    /// </summary>
    /// <param name="$keyParam">Unique $routeSegment id.</param>
    /// <response code="200">$featureName found.</response>
    /// <response code="404">$featureName not found.</response>
    [HttpGet]
    public async Task<ActionResult<$dtoName>> Get$featureName($keyType $keyParam)
    {
        var entity = await $serviceField.Get${featureName}Async($keyParam);
        if (entity == null)
        {
            return NotFound();
        }

        return Ok(entity);
    }

    /// <summary>
    /// Creates or updates a $routeSegment record.
    /// </summary>
    /// <param name="$controllerDtoVar">Payload to create or update.</param>
    /// <response code="200">$featureName created or updated.</response>
    /// <response code="400">Request body failed validation.</response>
    [HttpPut]
    public async Task<ActionResult<$dtoName>> Update$featureName([FromBody] $dtoName $controllerDtoVar)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var updatedEntity = await $serviceField.CreateOrUpdate${featureName}Async($controllerDtoVar);
        return Ok(updatedEntity);
    }
}
"@

if ($DryRun) {
    Write-Host "Dry run - generated artifacts:"
    Write-Host "  $modelPath"
    Write-Host "  $interfacePath"
    Write-Host "  $servicePath"
    Write-Host "  $controllerPath"
}
else {
    Write-FileSafe -Path $modelPath -Content ($modelLines -join "`r`n") -AllowOverwrite:$Force
    Write-FileSafe -Path $interfacePath -Content $interfaceContent -AllowOverwrite:$Force
    Write-FileSafe -Path $servicePath -Content $serviceContent -AllowOverwrite:$Force
    Write-FileSafe -Path $controllerPath -Content $controllerContent -AllowOverwrite:$Force
}

$dbContextLines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $dbContextPath)
$dbSetLine = "    public DbSet<$entityName> $dbSetName { get; set; }"

if (-not ($dbContextLines -contains $dbSetLine)) {
    $dbSetInsertAt = -1
    for ($i = 0; $i -lt $dbContextLines.Count; $i++) {
        if ($dbContextLines[$i] -match '^\s*public DbSet<.+>\s+\w+\s+\{\s*get;\s*set;\s*\}\s*$') {
            $dbSetInsertAt = $i + 1
        }
    }
    if ($dbSetInsertAt -lt 0) {
        throw "Could not locate DbSet declarations in ApplicationDbContext."
    }
    Add-IndentedBlock -Lines $dbContextLines -InsertAt $dbSetInsertAt -Block @("", $dbSetLine)
}

$entityConfigSignature = "        modelBuilder.Entity<$entityName>(entity =>"
if (-not ($dbContextLines -contains $entityConfigSignature)) {
    $methodStart = -1
    for ($i = 0; $i -lt $dbContextLines.Count; $i++) {
        if ($dbContextLines[$i] -match '^\s*protected override void OnModelCreating\(ModelBuilder modelBuilder\)') {
            $methodStart = $i
            break
        }
    }
    if ($methodStart -lt 0) {
        throw "Could not locate OnModelCreating in ApplicationDbContext."
    }

    $depth = 0
    $methodEnd = -1
    for ($i = $methodStart; $i -lt $dbContextLines.Count; $i++) {
        $line = $dbContextLines[$i]
        $openCount = ([regex]::Matches($line, '\{')).Count
        $closeCount = ([regex]::Matches($line, '\}')).Count
        $depth += $openCount
        $depth -= $closeCount
        if ($i -gt $methodStart -and $depth -eq 0) {
            $methodEnd = $i
            break
        }
    }

    if ($methodEnd -lt 0) {
        throw "Could not determine end of OnModelCreating."
    }

    $entityBlock = New-Object System.Collections.Generic.List[string]
    $entityBlock.Add("")
    $entityBlock.Add("        modelBuilder.Entity<$entityName>(entity =>")
    $entityBlock.Add("        {")
    $entityBlock.Add("            entity.HasKey(e => e.$keyName);")
    foreach ($field in $fieldSpecs) {
        if ($field.IsString -and $field.MaxLength) {
            $entityBlock.Add("            entity.Property(e => e.$($field.Name)).HasMaxLength($($field.MaxLength));")
        }
    }
    if ($useTimestamps) {
        $entityBlock.Add("            entity.Property(e => e.CreatedAt).HasDefaultValueSql(""CURRENT_TIMESTAMP"");")
        $entityBlock.Add("            entity.Property(e => e.UpdatedAt).HasDefaultValueSql(""CURRENT_TIMESTAMP"");")
    }
    $entityBlock.Add("        });")

    Add-IndentedBlock -Lines $dbContextLines -InsertAt $methodEnd -Block $entityBlock
}

$programLines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $programPath)
$registrationLine = "builder.Services.AddScoped<$interfaceName, $serviceName>();"
if (-not ($programLines -contains $registrationLine)) {
    $lastAddScopedIndex = -1
    for ($i = 0; $i -lt $programLines.Count; $i++) {
        if ($programLines[$i] -match '^\s*builder\.Services\.AddScoped<') {
            $lastAddScopedIndex = $i
        }
    }

    if ($lastAddScopedIndex -ge 0) {
        Add-IndentedBlock -Lines $programLines -InsertAt ($lastAddScopedIndex + 1) -Block @($registrationLine)
    }
    else {
        $addControllersIndex = -1
        for ($i = 0; $i -lt $programLines.Count; $i++) {
            if ($programLines[$i] -match '^\s*builder\.Services\.AddControllers\(\);') {
                $addControllersIndex = $i
                break
            }
        }
        if ($addControllersIndex -lt 0) {
            throw "Could not determine where to add service registration in Program.cs."
        }
        Add-IndentedBlock -Lines $programLines -InsertAt ($addControllersIndex + 1) -Block @($registrationLine)
    }
}

if (-not $DryRun) {
    Set-Content -LiteralPath $dbContextPath -Value ($dbContextLines -join "`r`n") -Encoding UTF8
    Set-Content -LiteralPath $programPath -Value ($programLines -join "`r`n") -Encoding UTF8
    Write-Host "Scaffold complete for feature '$featureName'."
}
else {
    Write-Host "Dry run complete. No files were written."
}
