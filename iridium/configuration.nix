{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings = {
    auto-optimise-store = true;
    allowed-users = [ "@wheel" ];
    trusted-users = [
      "root"
      "@wheel"
    ];
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
    ];
    # Unused while no CUDA build is in the closure (cudaSupport unset,
    # sunshine/ollama disabled) — dropping it yields a byte-identical system.
    # Re-enable by changing the `];` above to:
    #   ] || pkgs._cuda.lib.allowUnfreeCudaPredicate pkg;
  };
  system.stateVersion = "26.05";
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [ "threadirqs" ];
    kernelModules = [ "uinput" ];
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
    };
    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    lanzaboote = {
      enable = true;
      configurationLimit = 16;
      pkiBundle = "/var/lib/sbctl";
    };
    tmp.cleanOnBoot = true;
    initrd = {
      kernelModules = [
        "nvidia"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia_uvm"
      ];
      systemd = {
        enable = true;
        tpm2.enable = true;
        services.rollback = {
          description = "Rollback @ subvolume";
          wantedBy = [ "initrd.target" ];
          after = [ "dev-mapper-cryptroot.device" ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = false;
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /mnt
            mount -t btrfs /dev/mapper/cryptroot /mnt
            btrfs subvolume delete /mnt/@/srv 2>/dev/null || true
            btrfs subvolume delete /mnt/@/tmp 2>/dev/null || true
            btrfs subvolume delete /mnt/@
            btrfs subvolume snapshot /mnt/@blank /mnt/@
            btrfs subvolume delete /mnt/@home
            btrfs subvolume snapshot /mnt/@home-blank /mnt/@home
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
  swapDevices = [{
    device = "/swap/.swapfile";
    size = 8192;
  }];
  networking = {
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
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
    i2c.enable = true;
    nvidia = {
      open = true;
      nvidiaSettings = true;
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
  powerManagement.cpuFreqGovernor = "performance";
  security = {
    pam = {
      services = {
        su.rootOK = lib.mkForce false;
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        ly.u2fAuth = true;
      };
      u2f = {
        enable = true;
        control = "sufficient";
        settings = {
          authfile = config.sops.secrets.authorized_passkeys.path;
          cue = true;
          cue_prompt = "Touch the gold on the key to continue.";
        };
      };
    };
    protectKernelImage = true;
    # lockKernelModules = true; # incompatible with the current setup
    rtkit.enable = true;
    # Drop the cap_sys_nice that programs.hyprland's wrapper grants: it leaks
    # into every child app's ambient set, so xdg-desktop-portal (capless) fails
    # cap_ptrace_access_check on the app's /proc/PID/root and screen sharing
    # breaks for Chromium/Electron apps. We forgo Hyprland's self-SCHED_RR.
    wrappers.Hyprland.capabilities = lib.mkForce "";
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
  sops = {
    age.sshKeyPaths = [ "/var/lib/ssh/ssh_host_ed25519_key" ];
    secrets = {
      tailscale_auth_key = {
        sopsFile = ../secrets/iridium/tailscale.yaml;
        key = "auth_key";
      };
      jaxxen_hashed_password = {
        sopsFile = ../secrets/iridium/jaxxen/password.yaml;
        key = "hashed_password";
        neededForUsers = true;
      };
      authorized_passkeys = {
        sopsFile = ../secrets/iridium/authorized_passkeys.yaml;
        key = "authorized_passkeys";
        neededForUsers = true;
      };
    };
  };
  services = {
    displayManager.ly.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    hardware.openrgb = {
      enable = true;
      motherboard = "amd";
    };
    openssh = {
      enable = true;
      hostKeys = [{
        path = "/var/lib/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
      settings = {
        KbdInteractiveAuthentication = false;
        MaxAuthTries = 3;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [
          "1.1.1.1"
          "1.0.0.1"
          "9.9.9.9"
          "149.112.112.112"
        ];
        DNSSEC = true;
        DNSOverTLS = "yes";
        Domains = [ "~." ];
      };
    };
    sunshine = {
      enable = false;
      autoStart = false;
      capSysAdmin = true;
      package = pkgs.sunshine.override {
        cudaSupport = true;
      };
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      extraUpFlags = [
        "--advertise-tags=tag:iridium"
        "--ssh"
      ];
    };
    udisks2.enable = true;
    udev.extraRules = ''
      KERNEL=="nvidia_uvm", GROUP="video", MODE="0660"
      SUBSYSTEM=="drm", DRIVERS=="nvidia", TAG+="master-of-seat"
      KERNEL=="uinput", MODE="0660", GROUP="input", TAG+="uaccess", SYMLINK+="uinput"
    '';
    xserver.videoDrivers = [ "nvidia" ];
  };
  environment = {
    binsh = "${pkgs.dash}/bin/dash";
    systemPackages = with pkgs; [
      age
      qemu_kvm
      sbctl
      sops
      ssh-to-age
      swtpm
      alacritty.terminfo
      foot.terminfo
      ghostty.terminfo
      kitty.terminfo
      wezterm.terminfo
    ];
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/lib"
        "/var/log"
      ];
      users.jaxxen = {
        directories = [
          ".claude"
          ".librewolf"
          ".local/share"
          ".local/state/nix"
          ".ollama"
          "Documents"
          "Pictures"
          "Projects"
        ];
        files = [
          ".ssh/known_hosts"
          ".ssh/id_ed25519_sk"
          ".ssh/id_ed25519_sk_backup"
        ];
      };
    };
  };
  programs = {
    gamemode.enable = true;
    hyprland.enable = true;
    nh = {
      enable = true;
      clean = {
        dates = "weekly";
        extraArgs = "--keep 16";
      };
    };
    steam.enable = true;
    wireshark.enable = true;
    yubikey-manager.enable = true;
    zsh.enable = true;
  };
  users = {
    mutableUsers = false;
    motd = "Welcome to Iridium";
    groups.jaxxen = {};
    users = {
      jaxxen = {
        isNormalUser = true;
        group = "jaxxen";
        shell = pkgs.zsh;
        extraGroups = [
          "audio"
          "input"
          "kvm"
          "networkmanager"
          "tty"
          "video"
          "wheel"
          "wireshark"
        ];
        openssh.authorizedKeys.keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINf5O1PF7EOI+5OZ0WroFKzgJnWHv8RDwh2R3+HqPs6YAAAACnNzaDpqYXh4ZW4= jaxxen@yubikey"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMV+xxHgt/f+M4kJn3HZPBe2kHSqbH0ym8mZ6V+4GyP9AAAACnNzaDpqYXh4ZW4= jaxxen@yubikey-backup"
        ];
        hashedPasswordFile = config.sops.secrets.jaxxen_hashed_password.path;
      };
      root.hashedPassword = "!";
    };
  };
  systemd = {
    services.nh-os-switch = {
      description = "Run nh os switch github:jaxxen-dev/vessel";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.nh}/bin/nh os switch github:jaxxen-dev/vessel";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
    timers.nh-os-switch = {
      description = "Weekly nh os switch (Monday 11am)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Mon 11:00";
        Persistent = true;
      };
    };
  };
  rehomify = {
    enable = true;
    users = [ "jaxxen" ];
  };
}
