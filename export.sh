#!/bin/bash
# Export script for app
# Creates a zip file excluding build artifacts, dependencies, and personal system data

echo "Collecting files to export..."

zip -r app.zip . \
  -x "node_modules/*" \
  -x "bin/*" \
  -x "obj/*" \
  -x "build/*" \
  -x "postgres_data/*" \
  -x "test-results/*" \
  -x "coverage/*" \
  -x ".nyc_output/*" \
  -x ".cache/*" \
  -x ".parcel-cache/*" \
  -x ".next/*" \
  -x ".nuget/*" \
  -x ".vscode/*" \
  -x ".idea/*" \
  -x ".terraform/*" \
  -x "*.user" \
  -x "*.suo" \
  -x "*.cache" \
  -x "*.dll" \
  -x "*.exe" \
  -x "*.pdb" \
  -x "*.log" \
  -x "*.tmp" \
  -x "*.temp" \
  -x ".DS_Store" \
  -x "Thumbs.db" \
  -x "ehthumbs.db" \
  -x "*.swp" \
  -x "*.swo" \
  -x "*~" \
  -x ".env" \
  -x ".env.local" \
  -x "appsettings.Development.json" \
  -x "appsettings.Production.json" \
  -x "*.pfx" \
  -x "*.key" \
  -x "*.pem" \
  -x "*.tfstate" \
  -x ".terraform.lock.hcl" \
  -x ".dockerignore" \
  -x "*.tgz" \
  -x "*.tar.gz" \
  -x "*.db" \
  -x "*.sqlite" \
  -x "*.sqlite3" \
  -x "CoverletSourceRootsMapping*"

echo "Export complete! Created app.zip"


