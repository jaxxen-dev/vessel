<!-- SPDX-License-Identifier: MIT
  -- Copyright (C) 2026 Jaxxen
  -->

# vessel

---

## Installation

> Check the drive you want Iridium installed to with `lsblk` and adjust line 9 of `iridium/disks.nix` accordingly.
> If the machine's hardware is new or different, regenerate `hardware-configuration.nix`.

```bash
./install.sh
```

---

## LUKS2 Keyslot Enrollment

For each Bio YubiKey (fingerprint only, no PIN fallback):

```bash
sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=no --fido2-with-user-verification=yes /dev/disk/by-partlabel/disk-main-luks
```

For each non-Bio YubiKey:

```bash
sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes /dev/disk/by-partlabel/disk-main-luks
```

Then, remove the passphrase:

```bash
sudo systemd-cryptenroll --wipe-slot=password /dev/disk/by-partlabel/disk-main-luks
```

Last, for measured boot, after Secure Boot is set up:

```bash
sudo systemd-cryptenroll --unlock-fido2-device=auto --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrlock=/var/lib/systemd/pcrlock.json /dev/disk/by-partlabel/disk-main-luks
```

---

## FIDO2 Credential Creation

Use `pamu2fcfg`:

- `-V` requires user verification (i.e. fingerprint, with PIN as fallback)
- `-N` requires PIN
- `-r` makes it a resident (discoverable) credential
- `-u USERNAME` sets the username the credential is for
- `-n` omits the username from the command's output
- `-o pam://iridium -i pam://iridium` makes PAM on Iridium the relying party

If the first YubiKey is a Bio model:

```bash
pamu2fcfg -Vru jaxxen -o pam://iridium -i pam://iridium > ~/fido.txt
```

If the first YubiKey is a non-Bio model:

```bash
pamu2fcfg -Nru jaxxen -o pam://iridium -i pam://iridium > ~/fido.txt
```

For each subsequent Bio YubiKey:

```bash
pamu2fcfg -Vrn -o pam://iridium -i pam://iridium >> ~/fido.txt
```

For each subsequent non-Bio YubiKey:

```bash
pamu2fcfg -Nrn -o pam://iridium -i pam://iridium >> ~/fido.txt
```

Once all your desired keys are added:

```bash
cd vessel && \
echo "fido: $(cat ~/fido.txt)" > secrets/fido.yaml && \
SOPS_AGE_KEY=AGE-PLUGIN-FIDO2-RK-1PE25CT \
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . age-plugin-fido2-rk nixpkgs#sops -c \
  sops --encrypt --in-place secrets/fido.yaml && \
shred -u ~/fido.txt
```

---

## License

MIT © 2025–2026 Jaxxen. See [LICENSE](./LICENSE).

---
