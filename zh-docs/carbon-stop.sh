#!/usr/bin/env bash
# Stop the local Carbon stack. Data volumes are preserved; `--purge` drops the
# worktree database too.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$ROOT/.tools/node-v24.22.1-darwin-arm64/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
export COREPACK_HOME="$ROOT/.tools/corepack"
export npm_config_cache="$ROOT/.tools/npm-cache"
export npm_config_store_dir="$ROOT/.tools/pnpm-store"

cd "$ROOT/carbon"
exec packages/dev/bin/crbn down "$@"
