# vessel

**Hardened NixOS workstation, meticulously tailored home-manager, and universal dev shell**

***100% reproducible from this repository.***

[![flake check](https://github.com/jaxxen-dev/vessel/actions/workflows/flake-check.yml/badge.svg)](https://github.com/jaxxen-dev/vessel/actions/workflows/flake-check.yml) [![NixOS](https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white)](https://nixos.org) [![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

**[Iridium](#iridium) · [Jaxxen's home-manager](#jaxxens-home-manager) · [Dev shell](#dev-shell) · [Maintenance](#maintenance) · [License](#license)**

---

Three things, one flake:

- **[Iridium](#iridium)** — a hardened NixOS workstation. Secure Boot end to end (Lanzaboote), a LUKS2-encrypted disk that can auto-unlock via TPM2, a root filesystem that rolls back to a clean state on every boot, and secrets sealed with sops-nix.
- **[Jaxxen's home-manager](#jaxxens-home-manager)** — a standalone user environment (Hyprland desktop, Zsh, Nixvim) that applies without touching the system and rides along on Iridium via [Rehomify](https://github.com/Ryokune/rehomify).
- **[Dev shell](#dev-shell)** — the same Zsh + Nixvim editing experience, one `nix develop` away on any machine with Nix.

It is **declarative and reproducible** — the whole machine is rebuilt from this repository — and **hands-off**: input updates land and activate weekly on their own, gated only by `nix flake check` (see [Maintenance](#maintenance)).

---

## Iridium

### About

- **System:** NixOS + Zen kernel + Lanzaboote (Secure Boot) + NVIDIA drivers
- **Disk:** LUKS2 (argon2id, iter-time 5000) → btrfs subvolumes, optionally TPM2-unlocked
- **Impermanence:** Rollback service wipes `@` and `@home` on every boot; declared portions of state persist at `/persist`
- **Rehomify:** Standalone home-manager configuration(s) reapplied on boot via [Rehomify](https://github.com/Ryokune/rehomify)
- **Secrets:** sops-nix/age, age key derived from SSH host key at `/var/lib/ssh/ssh_host_ed25519_key`
- **Network:** NetworkManager + DHCP, Tailscale (tag:iridium)

### Installation

> [!NOTE]
> `iridium/disks.nix` targets `/dev/nvme0n1`. Verify your drive with `lsblk` and adjust if needed.

In the NixOS installer:

```bash
passwd nixos # use a 7+ word passphrase
```

From your dev machine:

```bash
# replace TARGET_IP
ssh nixos@TARGET_IP
```

While SSH'd into the installer:

```bash
sudo -i
```

```bash
git clone https://github.com/jaxxen-dev/vessel.git
nix --experimental-features "nix-command flakes" run nixpkgs#disko -- --mode destroy,format,mount vessel/iridium/disks.nix
```

```bash
nixos-generate-config --root /mnt --no-filesystems --dir vessel/iridium
mkdir -p /mnt/persist/etc/nixos
cp -a vessel/. /mnt/persist/etc/nixos
nix --experimental-features "nix-command flakes" run nixpkgs#sbctl -- create-keys
mkdir -p /mnt/var/lib
mkdir -p /mnt/persist/var/lib
cp -r /var/lib/sbctl /mnt/var/lib/
cp -r /var/lib/sbctl /mnt/persist/var/lib/
nixos-install --flake /mnt/persist/etc/nixos#iridium
exit
```

```bash
exit
```

After the second `exit`, inject the SSH host key from your dev machine (with age key loaded):

> [!NOTE]
> sops-nix derives its age decryption key from the SSH host key. The key must exist before first boot or sops cannot decrypt any secret — including the user password and Tailscale auth key. On Iridium, `/var/lib` lives under impermanence persistence, so the injection target is `/mnt/persist/var/lib/ssh/` rather than `/mnt/etc/ssh/`.

```bash
# replace REPO_DIR and TARGET_IP
cd REPO_DIR

sops --extract '["ssh_host_ed25519_key"]' -d secrets/iridium/ssh.yaml \
  | ssh nixos@TARGET_IP \
    "sudo mkdir -p /mnt/persist/var/lib/ssh && sudo tee /mnt/persist/var/lib/ssh/ssh_host_ed25519_key > /dev/null && sudo chmod 600 /mnt/persist/var/lib/ssh/ssh_host_ed25519_key"
```

If all seems well, reboot Iridium.

### Secure Boot

> [!WARNING]
> Secure Boot isn't very securing if you don't have a UEFI password set.
> If you don't already have a UEFI password set, and you actually want to leverage the security benefits of Secure Boot, configure that password after following this section.
> Some UEFIs have a setting to allow the password to be reset by a hardware trick. Ensure you understand the implications of this and have your password backed up before disabling this.

Reboot into Iridium's UEFI, ensure Secure Boot is disabled, clear the current Secure Boot keys, apply your changes and reboot back into NixOS.

Once back in NixOS, log in / SSH in and run:

```bash
sudo sbctl enroll-keys --microsoft
```

> [!WARNING]
> `--microsoft` retains Microsoft's UEFI CA alongside your own keys. Required for most consumer motherboards that ship GPU option ROMs signed by Microsoft. Omit only if you are certain your firmware has no Microsoft-signed components.

Reboot into UEFI again and re-enable Secure Boot. Apply your changes, reboot back into NixOS, and verify the status of Secure Boot with:

```bash
sbctl status
```

### TPM2 automatic LUKS unlock

If you chose to properly set up Secure Boot, you may want to leverage TPM2 to automatically unlock Iridium's LUKS.

To best enable this feature, bind LUKS to the TPM against PCR 0+7 (firmware + Secure Boot state):

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
```

Reboot and verify LUKS unlocks automatically without a passphrase prompt.

---

## Jaxxen's home-manager

### About

- **Standalone home-manager:** No elevated permissions required to manage your user-level configurations
- **Zsh:** Powerlevel10k instant prompt + autosuggestions + syntax highlighting + vim-style navigation
- **Nixvim:** Treesitter + LSP for nix/md/js/ts/py
- **Desktop:** Personalized Hyprland + WezTerm + Rofi + Dunst + LibreWolf
- **Theme:** Maple Mono NF + TokyoNight Night (WezTerm) + Catppuccin Mocha (Nixvim)

### Installation

While logged in as jaxxen:

```bash
nh home switch github:jaxxen-dev/vessel
```

---

## Dev shell

### About

- **Universal:** Accessible from any system with Nix via a single command
- **Zsh:** Powerlevel10k instant prompt, autosuggestions, syntax highlighting, & vim-style navigation
- **Nixvim:** Treesitter, LSP for nix+md+js+ts+py, Catppuccin Mocha theme
- **Packages:** nh, git, sops, age, ssh-to-age, ...

### Usage

```bash
nix develop github:jaxxen-dev/vessel
```

---

## Maintenance

### Rebuilding

Apply changes after editing the flake:

```bash
nh os switch              # rebuild + activate the NixOS system (Iridium)
nh home switch            # rebuild + activate Jaxxen's home-manager
nh os switch --update     # bump flake inputs, then rebuild the system
nix flake check           # what CI runs on every PR
./ci.sh                   # run the full CI suite locally, before committing
```

> [!NOTE]
> `main` is branch-protected — never push to it directly. Open a PR; CI runs `nix flake check` automatically.

### Hands-off updates

Iridium keeps itself current against `main` with no manual step, via two weekly jobs:

| When (UTC / local) | What |
|---|---|
| Mon 06:00 UTC | [`flake-update.yml`](.github/workflows/flake-update.yml) runs `nix flake update`, opens a PR, and **auto-merges** it once `flake-check` passes. |
| Mon 11:00 local | The `nh-os-switch` systemd timer pulls `github:jaxxen-dev/vessel` and runs `nh os switch` as root. |

So upstream input bumps land and activate on their own, gated solely by `nix flake check` going green. That keeps the gate load-bearing — unreviewed upstream changes activate as root — so it's worth keeping meaningful. To intervene, merge or close the weekly PR before the timer fires, or run `nh os switch --update` yourself.

---

## License

MIT © 2025 Jaxxen. See [LICENSE](LICENSE).
