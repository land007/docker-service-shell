#!/bin/bash
set -euo pipefail

cd /app

if [ ! -f package.json ]; then
  echo "package.json was not found in /app" >&2
  exit 1
fi

if [ ! -f node_modules/next/package.json ]; then
  echo "Installing dependencies into the dev volume..."
  npm ci
fi

exec /bin/bash -lc "${DEV_COMMAND:-npm run dev}"
