/* SPDX-License-Identifier: MIT
 * Copyright (C) 2026 Jaxxen
 */

{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings = {
    auto-optimise-store = true;
    allowed-users = [ "jaxxen" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    use-xdg-base-directories = true;
  };
  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "nvidia-persistenced"
      "nvidia-settings"
      "nvidia-x11"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
      "claude"
    ];
  };
  system.stateVersion = "26.05";
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "threadirqs"
      "slab_nomerge"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "debugfs=off"
    ];
    kernel.sysctl = {
      "fs.file-max" = 524288;
      "vm.max_map_count" = 1048576;
      "vm.page-cluster" = 0;
      "vm.swappiness" = 100;
      "vm.watermark_scale_factor" = 150;
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "kernel.yama.ptrace_scope" = 2;
      "net.core.rmem_max" = 4194304;
      "net.core.wmem_max" = 4194304;
      "kernel.sysrq" = 0;
      "dev.tty.ldisc_autoload" = 0;
      "fs.suid_dumpable" = 0;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };
    blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
    ];
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 4;
      autoGenerateKeys.enable = true;
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
    };
    loader = {
      systemd-boot.editor = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    tmp.useTmpfs = true;
    initrd = {
      kernelModules = [
        "nvidia"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia_uvm"
      ];
      systemd = {
        tpm2.enable = false;
        services.rollback = {
          description = "Rollback @ subvolume";
          wantedBy = [ "initrd.target" ];
          requires = [ "dev-mapper-cryptroot.device" ];
          after = [ "dev-mapper-cryptroot.device" ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = false;
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /mnt
            mount -t btrfs /dev/mapper/cryptroot /mnt
            btrfs subvolume delete -R /mnt/@
            btrfs subvolume snapshot /mnt/@blank /mnt/@
            btrfs subvolume delete -R /mnt/@home
            btrfs subvolume snapshot /mnt/@blank /mnt/@home
            btrfs subvolume delete -R /mnt/@var
            btrfs subvolume snapshot /mnt/@blank /mnt/@var
            umount /mnt
          '';
        };
      };
    };
  };
  fileSystems = {
    "/persist".neededForBoot = true;
    "/home".neededForBoot = true;
    "/var".neededForBoot = true;
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;
  };
  sops = {
    age.keyFile = "/persist/var/lib/sops-nix/iridium.txt";
    secrets.fido = {
      sopsFile = ../secrets/fido.yaml;
      owner = "root";
      group = "jaxxen";
      mode = "0440";
    };
  };
  systemd = {
    coredump.settings.Coredump.Storage = "none";
    tpm2.enable = false;
  };
  networking = {
    firewall.enable = true;
    hostName = "iridium";
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
  };
  time.timeZone = "America/Chicago";
  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  hardware = {
    nvidia = {
      open = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vulkan-loader
        vulkan-validation-layers
      ];
    };
  };
  # powerManagement.cpuFreqGovernor = "performance";
  security = {
    pam = {
      services = {
        su.rootOK = lib.mkForce false;
        login.u2f.enable = true;
        sudo.u2f.enable = true;
        ly.u2f.enable = true;
        waylock.u2f.enable = true;
      };
      u2f = {
        enable = true;
        control = "sufficient";
        settings = {
          cue = true;
          cue_prompt = "pam: touch your key...";
          authfile = config.sops.secrets.fido.path;
        };
      };
    };
    protectKernelImage = true;
    # lockKernelModules = true; # incompatible with the current setup
    rtkit.enable = true;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
  services = {
    displayManager.ly.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    mullvad-vpn.enable = true;
    pipewire.enable = true;
    resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
          "2606:4700:4700::1111#cloudflare-dns.com"
          "2606:4700:4700::1001#cloudflare-dns.com"
        ];
        DNSOverTLS = "yes";
        DNSSEC = true;
        Domains = [ "~." ];
        LLMNR = "no";
        MulticastDNS = "no";
      };
    };
    udisks2.enable = true;
    udev.extraRules = ''
      KERNEL=="nvidia_uvm", GROUP="jaxxen", MODE="0660"
      SUBSYSTEM=="drm", DRIVERS=="nvidia", TAG+="master-of-seat"
    '';
    xserver.videoDrivers = [ "nvidia" ];
  };
  environment = {
    binsh = "${pkgs.dash}/bin/dash";
    systemPackages = with pkgs; [
      qemu_kvm
      sbctl
    ];
    pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/lib"
        "/var/log"
      ];
      files = [ "/etc/machine-id" ];
      users.jaxxen = {
        directories = [
          ".claude"
          ".local/share"
          "documents"
          "pictures"
          "projects"
        ];
        files = [
          ".ssh/id_ed25519_sk"
          ".ssh/known_hosts"
        ];
      };
    };
  };
  programs = {
    gamemode.enable = true;
    hyprland.enable = true;
    nh = {
      enable = true;
      flake = "/home/jaxxen/projects/vessel";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 4";
      };
    };
    steam.enable = true;
    yubikey-manager.enable = true;
    zsh.enable = true;
  };
  users = {
    mutableUsers = false;
    allowNoPasswordLogin = true;
    users = {
      root.hashedPassword = "!";
      jaxxen = {
        isNormalUser = true;
        hashedPassword = "!";
        shell = pkgs.zsh;
        group = "jaxxen";
        extraGroups = [
          "wheel"
          "networkmanager"
          "kvm"
        ];
      };
    };
    groups.jaxxen = {};
  };
}
