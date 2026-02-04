#!/usr/bin/env bash
set -euo pipefail

# VS Code Checksum Update Script
# Updates checksums in product.json after theme injection

echo "=== UPDATING VS CODE CHECKSUMS (postFixup) ==="
VSCODE_APP="$out/lib/vscode/resources/app"
PRODUCT_JSON="$VSCODE_APP/product.json"

if [[ -f "$PRODUCT_JSON" ]]; then
  chmod u+w "$PRODUCT_JSON"
  OUTDIR="$VSCODE_APP/out"
  cp "$PRODUCT_JSON" "$PRODUCT_JSON.bak"
  CHECKSUMS_JSON="{"
  first=true

  for key in $(@JQ_BIN@ -r '.checksums | keys[]' "$PRODUCT_JSON"); do
    filepath="$OUTDIR/$key"
    if [[ -f "$filepath" ]]; then
      hash=$(@OPENSSL_BIN@ dgst -sha256 -binary "$filepath" | base64 -w0 | sed 's/=*$//')
      if [[ "$first" == "true" ]]; then
        first=false
      else
        CHECKSUMS_JSON="$CHECKSUMS_JSON,"
      fi
      CHECKSUMS_JSON="$CHECKSUMS_JSON\"$key\":\"$hash\""
      echo "  ✓ $key"
    else
      echo "  ✗ File not found: $filepath"
    fi
  done

  CHECKSUMS_JSON="$CHECKSUMS_JSON}"
  @JQ_BIN@ --argjson cs "$CHECKSUMS_JSON" '.checksums = $cs' "$PRODUCT_JSON.bak" > "$PRODUCT_JSON"
  rm -f "$PRODUCT_JSON.bak"
  echo "✓ Checksums updated in product.json"
else
  echo "⚠ product.json not found, skipping checksum update"
fi