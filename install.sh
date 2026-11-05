#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Jaxxen

set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from . disko -- --mode destroy,format,mount ./iridium/disks.nix
SOPS_AGE_KEY=AGE-PLUGIN-FIDO2-RK-1PE25CT \
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . age-plugin-fido2-rk nixpkgs#sops -c \
  sops -d --extract '["iridium"]' secrets/iridium.yaml \
  | sudo install -Dm 0600 /dev/stdin /mnt/persist/var/lib/sops-nix/iridium.txt
sudo nixos-install --root /mnt --flake .#iridium --no-root-passwd
