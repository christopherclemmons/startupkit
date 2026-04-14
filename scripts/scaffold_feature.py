#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re
import sys
from typing import Any

try:
    import yaml
except ImportError:
    print(
        "PyYAML is required. Install with: pip3 install pyyaml",
        file=sys.stderr,
    )
    sys.exit(1)


def pascal_case(value: str) -> str:
    if not value or not value.strip():
        raise ValueError("Value cannot be empty when converting to PascalCase.")
    parts = [p for p in re.split(r"[^A-Za-z0-9]+", value) if p]
    if not parts:
        return value
    out = []
    for p in parts:
        out.append(p[:1].upper() + p[1:])
    return "".join(out)


def camel_case(value: str) -> str:
    p = pascal_case(value)
    return p[:1].lower() + p[1:]


def plural_name(singular: str) -> str:
    if re.search(r"[^aeiou]y$", singular):
        return singular[:-1] + "ies"
    if re.search(r"(s|x|z|ch|sh)$", singular):
        return singular + "es"
    return singular + "s"


def csharp_type(yaml_type: str, required: bool) -> str:
    normalized = (yaml_type or "").strip().lower()
    mapping = {
        "string": "string",
        "int": "int",
        "integer": "int",
        "long": "long",
        "guid": "Guid",
        "datetime": "DateTime",
        "bool": "bool",
        "boolean": "bool",
        "decimal": "decimal",
        "double": "double",
        "float": "float",
    }
    if normalized not in mapping:
        raise ValueError(f"Unsupported field type '{yaml_type}'.")
    base = mapping[normalized]
    if normalized == "string":
        return base if required else base + "?"
    return base if required else base + "?"


def write_file(path: pathlib.Path, content: str, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"File already exists: {path}. Use --force to overwrite.")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def find_method_end(lines: list[str], method_signature_pattern: str) -> int:
    method_start = -1
    for i, line in enumerate(lines):
        if re.search(method_signature_pattern, line):
            method_start = i
            break
    if method_start < 0:
        raise RuntimeError("Could not locate target method.")

    depth = 0
    started = False
    for i in range(method_start, len(lines)):
        line = lines[i]
        opens = line.count("{")
        closes = line.count("}")
        if opens:
            started = True
        depth += opens
        depth -= closes
        if started and i > method_start and depth == 0:
            return i
    raise RuntimeError("Could not determine end of method body.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Scaffold .NET API feature from YAML spec.")
    parser.add_argument("--spec-path", required=True, help="Path to YAML feature spec.")
    parser.add_argument("--api-root", default="src/backend/API", help="API root path.")
    parser.add_argument("--dry-run", action="store_true", help="Show changes without writing files.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing generated files.")
    args = parser.parse_args()

    spec_path = pathlib.Path(args.spec_path).resolve()
    if not spec_path.exists():
        raise FileNotFoundError(f"Spec file not found: {spec_path}")

    spec = yaml.safe_load(spec_path.read_text(encoding="utf-8"))
    if not isinstance(spec, dict) or "feature" not in spec:
        raise ValueError("Spec must include top-level 'feature' object.")
    feature: dict[str, Any] = spec["feature"]

    feature_name = pascal_case(feature["name"])
    entity_name = pascal_case(feature.get("entity_name", feature_name))
    dto_name = pascal_case(feature.get("dto_name", f"{entity_name}Dto"))
    service_name = pascal_case(feature.get("service_name", f"{feature_name}Service"))
    interface_name = pascal_case(feature.get("interface_name", f"I{service_name}"))
    controller_name = pascal_case(feature.get("controller_name", f"{feature_name}Controller"))
    dbset_name = pascal_case(feature.get("dbset_name", plural_name(entity_name)))
    route_segment = str(feature.get("route_segment", feature_name.lower())).strip()
    use_timestamps = bool(feature.get("timestamps", True))

    key = feature.get("key")
    if not isinstance(key, dict):
        raise ValueError("Spec must include feature.key with name/type.")
    key_name = pascal_case(key["name"])
    key_param = camel_case(key_name)
    key_required = bool(key.get("required", True))
    key_type = csharp_type(key["type"], key_required)

    raw_fields = feature.get("fields", []) or []
    fields = []
    for f in raw_fields:
        required = bool(f.get("required", False))
        fields.append(
            {
                "name": pascal_case(f["name"]),
                "type": csharp_type(f["type"], required),
                "required": required,
                "max_length": f.get("max_length"),
                "is_string": str(f["type"]).strip().lower() == "string",
            }
        )

    api_root = pathlib.Path(args.api_root).resolve()
    model_path = api_root / "Models" / f"{entity_name}.cs"
    interface_path = api_root / "Services" / f"{interface_name}.cs"
    service_path = api_root / "Services" / f"{service_name}.cs"
    controller_path = api_root / "Controllers" / f"{controller_name}.cs"
    db_context_path = api_root / "Data" / "ApplicationDbContext.cs"
    program_path = api_root / "Program.cs"

    model_lines = [
        "using System.ComponentModel.DataAnnotations;",
        "",
        "namespace API.Models;",
        "",
        f"public class {entity_name}",
        "{",
        f"    public {key_type} {key_name} {{ get; set; }}",
    ]
    for field in fields:
        model_lines.append("")
        if field["max_length"] is not None:
            model_lines.append(f"    [MaxLength({field['max_length']})]")
        if field["required"]:
            model_lines.append("    [Required]")
        if field["is_string"] and field["required"]:
            model_lines.append(f"    public {field['type']} {field['name']} {{ get; set; }} = string.Empty;")
        else:
            model_lines.append(f"    public {field['type']} {field['name']} {{ get; set; }}")
    if use_timestamps:
        model_lines.extend(
            [
                "",
                "    public DateTime CreatedAt { get; set; }",
                "",
                "    public DateTime UpdatedAt { get; set; }",
            ]
        )
    model_lines.extend(
        [
            "}",
            "",
            f"public class {dto_name}",
            "{",
            "    [Required]",
            f"    public {key_type} {key_name} {{ get; set; }}",
        ]
    )
    for field in fields:
        model_lines.append("")
        if field["max_length"] is not None:
            model_lines.append(f"    [MaxLength({field['max_length']})]")
        if field["required"]:
            model_lines.append("    [Required]")
        if field["is_string"] and field["required"]:
            model_lines.append(f"    public {field['type']} {field['name']} {{ get; set; }} = string.Empty;")
        else:
            model_lines.append(f"    public {field['type']} {field['name']} {{ get; set; }}")
    model_lines.append("}")

    feature_dto_var = camel_case(feature_name) + "Dto"
    interface_content = f"""using API.Models;

namespace API.Services;

public interface {interface_name}
{{
    Task<{dto_name}?> Get{feature_name}Async({key_type} {key_param});
    Task<{dto_name}> CreateOrUpdate{feature_name}Async({dto_name} {feature_dto_var});
}}
"""

    entity_to_dto = [f"            {key_name} = entity.{key_name}"] + [
        f"            {f['name']} = entity.{f['name']}" for f in fields
    ]
    dto_to_entity = [f"                {key_name} = {feature_dto_var}.{key_name}"] + [
        f"                {f['name']} = {feature_dto_var}.{f['name']}" for f in fields
    ]
    update_assignments = [
        f"            entity.{f['name']} = {feature_dto_var}.{f['name']};" for f in fields
    ]

    if use_timestamps:
        dto_to_entity.extend(
            [
                "                CreatedAt = DateTime.UtcNow",
                "                UpdatedAt = DateTime.UtcNow",
            ]
        )

    entity_to_dto_block = ",\n".join(entity_to_dto)
    dto_to_entity_block = ",\n".join(dto_to_entity)
    update_assignments_block = "\n".join(update_assignments)
    timestamp_update_line = "            entity.UpdatedAt = DateTime.UtcNow;" if use_timestamps else ""

    service_content = f"""using Microsoft.EntityFrameworkCore;
using API.Data;
using API.Models;

namespace API.Services;

public class {service_name} : {interface_name}
{{
    private readonly ApplicationDbContext _context;

    public {service_name}(ApplicationDbContext context)
    {{
        _context = context;
    }}

    public async Task<{dto_name}?> Get{feature_name}Async({key_type} {key_param})
    {{
        var entity = await _context.{dbset_name}
            .FirstOrDefaultAsync(e => e.{key_name} == {key_param});

        if (entity == null)
        {{
            return null;
        }}

        return new {dto_name}
        {{
{entity_to_dto_block}
        }};
    }}

    public async Task<{dto_name}> CreateOrUpdate{feature_name}Async({dto_name} {feature_dto_var})
    {{
        var entity = await _context.{dbset_name}
            .FirstOrDefaultAsync(e => e.{key_name} == {feature_dto_var}.{key_name});

        if (entity == null)
        {{
            entity = new {entity_name}
            {{
{dto_to_entity_block}
            }};
            _context.{dbset_name}.Add(entity);
        }}
        else
        {{
{update_assignments_block}
{timestamp_update_line}
            _context.{dbset_name}.Update(entity);
        }}

        await _context.SaveChangesAsync();

        return new {dto_name}
        {{
{entity_to_dto_block}
        }};
    }}
}}
"""

    service_field = "_" + camel_case(feature_name) + "Service"
    controller_content = f"""using Microsoft.AspNetCore.Mvc;
using API.Models;
using API.Services;

namespace API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class {controller_name} : ControllerBase
{{
    private readonly {interface_name} {service_field};

    public {controller_name}({interface_name} {service_field})
    {{
        this.{service_field} = {service_field};
    }}

    /// <summary>
    /// Gets a single {route_segment} by {key_param}.
    /// </summary>
    /// <param name="{key_param}">Unique {route_segment} id.</param>
    /// <response code="200">{feature_name} found.</response>
    /// <response code="404">{feature_name} not found.</response>
    [HttpGet]
    public async Task<ActionResult<{dto_name}>> Get{feature_name}({key_type} {key_param})
    {{
        var entity = await {service_field}.Get{feature_name}Async({key_param});
        if (entity == null)
        {{
            return NotFound();
        }}

        return Ok(entity);
    }}

    /// <summary>
    /// Creates or updates a {route_segment} record.
    /// </summary>
    /// <param name="{feature_dto_var}">Payload to create or update.</param>
    /// <response code="200">{feature_name} created or updated.</response>
    /// <response code="400">Request body failed validation.</response>
    [HttpPut]
    public async Task<ActionResult<{dto_name}>> Update{feature_name}([FromBody] {dto_name} {feature_dto_var})
    {{
        if (!ModelState.IsValid)
        {{
            return BadRequest(ModelState);
        }}

        var updatedEntity = await {service_field}.CreateOrUpdate{feature_name}Async({feature_dto_var});
        return Ok(updatedEntity);
    }}
}}
"""

    planned = [model_path, interface_path, service_path, controller_path]
    if args.dry_run:
        print("Dry run - generated artifacts:")
        for p in planned:
            print(f"  {p}")
    else:
        write_file(model_path, "\n".join(model_lines) + "\n", args.force)
        write_file(interface_path, interface_content, args.force)
        write_file(service_path, service_content, args.force)
        write_file(controller_path, controller_content, args.force)

    db_lines = db_context_path.read_text(encoding="utf-8").splitlines()
    dbset_line = f"    public DbSet<{entity_name}> {dbset_name} {{ get; set; }}"
    if dbset_line not in db_lines:
        insert_at = -1
        for i, line in enumerate(db_lines):
            if re.match(r"^\s*public DbSet<.+>\s+\w+\s+\{\s*get;\s*set;\s*\}\s*$", line):
                insert_at = i + 1
        if insert_at < 0:
            raise RuntimeError("Could not locate DbSet declarations in ApplicationDbContext.")
        db_lines[insert_at:insert_at] = ["", dbset_line]

    entity_sig = f"        modelBuilder.Entity<{entity_name}>(entity =>"
    if entity_sig not in db_lines:
        method_end = find_method_end(
            db_lines, r"^\s*protected override void OnModelCreating\(ModelBuilder modelBuilder\)"
        )
        entity_block = [
            "",
            f"        modelBuilder.Entity<{entity_name}>(entity =>",
            "        {",
            f"            entity.HasKey(e => e.{key_name});",
        ]
        for f in fields:
            if f["is_string"] and f["max_length"] is not None:
                entity_block.append(
                    f"            entity.Property(e => e.{f['name']}).HasMaxLength({f['max_length']});"
                )
        if use_timestamps:
            entity_block.append(
                '            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");'
            )
            entity_block.append(
                '            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");'
            )
        entity_block.append("        });")
        db_lines[method_end:method_end] = entity_block

    program_lines = program_path.read_text(encoding="utf-8").splitlines()
    reg_line = f"builder.Services.AddScoped<{interface_name}, {service_name}>();"
    if reg_line not in program_lines:
        last_add_scoped = -1
        for i, line in enumerate(program_lines):
            if re.match(r"^\s*builder\.Services\.AddScoped<", line):
                last_add_scoped = i
        if last_add_scoped >= 0:
            program_lines[last_add_scoped + 1 : last_add_scoped + 1] = [reg_line]
        else:
            add_controllers = -1
            for i, line in enumerate(program_lines):
                if re.match(r"^\s*builder\.Services\.AddControllers\(\);", line):
                    add_controllers = i
                    break
            if add_controllers < 0:
                raise RuntimeError("Could not locate AddControllers in Program.cs.")
            program_lines[add_controllers + 1 : add_controllers + 1] = [reg_line]

    if args.dry_run:
        print("Dry run complete. No files were written.")
    else:
        db_context_path.write_text("\n".join(db_lines) + "\n", encoding="utf-8", newline="\n")
        program_path.write_text("\n".join(program_lines) + "\n", encoding="utf-8", newline="\n")
        print(f"Scaffold complete for feature '{feature_name}'.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
