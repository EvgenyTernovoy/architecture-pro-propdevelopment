#!/bin/sh
set -e

ROLES_DIR="./roles"

echo "==> Applying RBAC roles..."
for file in "$ROLES_DIR"/*.yaml; do
  if [ -f "$file" ]; then
    echo "Applying $file"
    kubectl apply -f "$file"
  fi
done

echo "==> Done."