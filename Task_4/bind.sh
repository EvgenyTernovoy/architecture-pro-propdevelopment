#!/bin/sh
set -e

BINDINGS_DIR="./bindings"

echo "==> Applying RBAC role bindings..."
for file in "$BINDINGS_DIR"/*.yaml; do
  if [ -f "$file" ]; then
    echo "Applying $file"
    kubectl apply -f "$file"
  fi
done

echo "==> Done."