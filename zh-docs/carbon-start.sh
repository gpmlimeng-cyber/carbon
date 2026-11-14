#!/usr/bin/env bash
# Start the local Carbon stack (ERP + MES + Supabase + Redis + Inngest).
# Prerequisite: Docker Desktop is running.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CARBON_ROOT="$ROOT/carbon"
export PATH="$ROOT/.tools/node-v24.22.1-darwin-arm64/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
export COREPACK_HOME="$ROOT/.tools/corepack"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export npm_config_cache="$ROOT/.tools/npm-cache"
export npm_config_store_dir="$ROOT/.tools/pnpm-store"
export npm_config_registry="${npm_config_registry:-https://registry.npmmirror.com}"
# The Supabase CLI pulls postgres-meta from Docker Hub; go through the mirror.
export SUPABASE_INTERNAL_IMAGE_REGISTRY="${SUPABASE_INTERNAL_IMAGE_REGISTRY:-docker.1ms.run}"

if ! /Applications/Docker.app/Contents/Resources/bin/docker info >/dev/null 2>&1; then
  echo "Docker Desktop is not running — starting it..."
  open -a Docker
  for _ in $(seq 1 60); do
    if /Applications/Docker.app/Contents/Resources/bin/docker info >/dev/null 2>&1; then break; fi
    sleep 2
  done
fi

cd "$CARBON_ROOT"
exec packages/dev/bin/crbn up --no-portless --all --no-hibernate
