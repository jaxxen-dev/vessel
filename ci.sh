#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Jaxxen

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

ref=origin/main
workflow=.github/workflows/flake-check.yml
steps=$(nix run --inputs-from . nixpkgs#yq -- -r \
  '.jobs.check.steps[] | select(.run) | "echo; echo \"» \(.name)\"\n\(.run)"' \
  "$workflow")

if git rev-parse --verify --quiet "$ref" >/dev/null \
   && ! git diff --quiet "$ref" -- "$workflow"; then
  echo "⚠  $workflow differs from $ref — these commands will run as $(whoami):"
  printf '%s\n' "----------------------------------------" "$steps" "----------------------------------------"
  [ -t 0 ] || { echo "refusing to auto-run a modified workflow non-interactively."; exit 1; }
  read -rp "Proceed? [y/N] " reply
  [ "$reply" = y ] || [ "$reply" = Y ] || { echo "aborted."; exit 1; }
fi

bash -euo pipefail <<<"$steps"

echo
echo "✓ local CI passed"
