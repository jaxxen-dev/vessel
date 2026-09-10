{
  config,
  lib,
  pkgs,
  addons,
  ...
}:
let
  zsh = import ./zsh.nix {
    inherit pkgs;
  };
  utils = import ./utils.nix {
    inherit pkgs;
  };
  terminal = {
    name = "wezterm";
    command = "${pkgs.wezterm}/bin/wezterm -e";
  };
  font = {
    mono = {
      family = "Maple Mono NF";
      size = 12;
      package = pkgs.maple-mono.NF-unhinted; # if resolution >= 1440p, use NF-unhinted, else use NF
    };
    serif = {
      family = "Literata";
      size = 14;
      package = pkgs.literata;
    };
  };
in {
  home = {
    stateVersion = "26.05";
    username = "jaxxen";
    homeDirectory = "/home/jaxxen";
    file = {
      ".profile".text = ". ~/.local/state/nix/profile/etc/profile.d/hm-session-vars.sh";
      ".nix-profile".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/state/nix/profile";
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      PIPEWIRE_LATENCY = "96/48000";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.local/share/age/keys.txt";
      WINE_FULLSCREEN_FSR = "1";
    };
    pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Ice";
      size = 12;
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
    };
    file.".librewolf/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text = ''
      {
        "allowed_extensions": [ "keepassxc-browser@keepassxc.org" ],
        "description": "KeePassXC integration with native messaging support",
        "name": "org.keepassxc.keepassxc_browser",
        "path": "${pkgs.keepassxc}/bin/keepassxc-proxy",
        "type": "stdio"
      }
    '';
    packages = with pkgs; [
      awww
      claude-monitor
      font.mono.package
      font.serif.package
      libreoffice
      playerctl
      quickemu
      trash-cli
      ungoogled-chromium
      wiremix
      wl-clipboard-rs
      xdg-desktop-portal-termfilechooser
    ] ++ zsh.packages ++ utils;
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];
  news.display = "silent";
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ font.mono.family ];
      sansSerif = [ font.serif.family ];
      serif = [ font.serif.family ];
    };
  };
  programs = {
    home-manager.enable = true;
    bat.enable = true;
    bottom.enable = true;
    ccvm = {
      enable = true;
      cores = 8;
      memory = 8192;
      vmDiskSize = 32;
      nix.enable = true;
      extraPackages = utils;
    };
    claude-code = {
      enable = true;
      settings = {
        model = "opus";
        effortLevel = "xhigh";
        theme = "auto";
        attribution = {
          commit = "Co-authored-by: Claude <noreply@anthropic.com>";
          pr = "";
        };
        permissions = {
          defaultMode = "plan";
          allow = [
            "Read"
            "Bash(git log:*)"
            "Bash(git status:*)"
            "Bash(git diff:*)"
            "Bash(git show:*)"
            "Bash(git branch:*)"
            "Bash(ls:*)"
            "Bash(eza:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(cat:*)"
            "Bash(bat:*)"
            "Bash(echo:*)"
            "Bash(pwd:*)"
            "Bash(which:*)"
            "Bash(wc:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(jq:*)"
            "Bash(nix flake show:*)"
            "Bash(nix flake check:*)"
            "Bash(nix eval:*)"
          ];
        };
      };
      lspServers = {
        nixd = {
          command = "nixd";
          extensionToLanguage.".nix" = "nix";
        };
        typescript = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
          };
        };
        html = {
          command = "vscode-html-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".html" = "html";
            ".htm" = "html";
          };
        };
        css = {
          command = "vscode-css-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".css" = "css";
            ".scss" = "scss";
            ".less" = "less";
          };
        };
        rust = {
          command = "rust-analyzer";
          extensionToLanguage.".rs" = "rust";
        };
        python = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
          extensionToLanguage.".py" = "python";
        };
        eslint = {
          command = "vscode-eslint-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
          };
        };
        markdown = {
          command = "markdown-oxide";
          extensionToLanguage.".md" = "markdown";
        };
        json = {
          command = "vscode-json-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".json" = "json";
            ".jsonc" = "jsonc";
          };
        };
        yaml = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".yaml" = "yaml";
            ".yml" = "yaml";
          };
        };
      };
    };
    delta = {
      enable = true;
      enableGitIntegration = true;
    };
    eza = {
      enable = true;
      enableZshIntegration = true;
    };
    fd.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        pull.rebase = true;
        push.autoSetupRemote = true;
        user = {
          name = "Jaxxen";
          email = "git@jaxxen.dev";
        };
      };
      ignores = [
        "secrets/**/*.yaml.dec"
        "*.swp"
        "result"
        ".direnv"
        "**/.DS_Store"
      ];
    };
    gitui.enable = true;
    hyprlock.enable = true;
    hyprshot = {
      enable = true;
      saveLocation = "${config.home.homeDirectory}/Pictures/Screenshots";
    };
    imv = {
      enable = true;
      settings.binds = {
        r = "rotate by 90";
        R = "rotate by -90";
        z = "reset";
      };
    };
    jq.enable = true;
    keepassxc = {
      enable = true;
      settings = {
        SSHAgent.Enabled = true;
        Browser = {
          Enabled = true;
          UpdateBinaryPath = false;
        };
        PasswordGenerator = {
          AdvancedMode = true;
          Braces = true;
          Dashes = true;
          Logograms = true;
          Math = true;
          Punctuation = true;
          Quotes = true;
          WordSeparator = "-";
        };
        GUI = {
          HidePasswords = true;
          AdvancedSettings = true;
          CompactMode = true;
        };
      };
    };
    librewolf = {
      enable = true;
      profiles.${config.home.username} = {
        settings = {
          "privacy.resistFingerprinting" = false;
          "privacy.fingerprintingProtection" = true;
          "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
          "browser.toolbars.bookmarks.visibility" = "newtab";
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "extensions.autoDisableScopes" = 0;
          "widget.use-xdg-desktop-portal.settings" = 1;
        };
        extensions.packages = with addons; [
          ublock-origin
          keepassxc-browser
          df-youtube
          theater-mode-for-youtube
        ];
        bookmarks = {
          force = true;
          settings = [{
            name = "toolbar";
            toolbar = true;
            bookmarks = let
              bookmark = domain: {
                name = "";
                url = "https://${domain}";
              };
            in [
              (bookmark "mynixos.com")
              (bookmark "nixos.org")
              (bookmark "account.proton.me/switch")
            ];
          }];
        };
      };
      policies.ExtensionSettings = {
        "keepassxc-browser@keepassxc.org".private_browsing = true;
        "dfyoutube@example.com".private_browsing = true;
        "{b8326f03-322f-4112-96bd-e7996548d99f}".private_browsing = true;
      };
    };
    mpv = {
      enable = true;
      config = {
        prefetch-playlist = "yes";
        loop-playlist = "inf";
      };
    };
    nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/Projects/vessel";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 3";
      };
    };
    nixvim = {
      enable = true;
      defaultEditor = true;
      imports = [ ./nixvim.nix ];
    };
    prismlauncher = {
      enable = true;
      settings = {
        ApplicationTheme = "system";
        AutoCloseConsole = false;
        AutomaticJavaDownload = false;
        AutomaticJavaSwitch = true;
        BackgroundCat = "rory-flat";
        CatFit = "fit";
        CatOpacity = 100;
        CloseAfterLaunch = true;
        ConfigVersion = 1.3;
        ConsoleMaxLines = 1000;
        ConsoleOverflowStop = true;
        EnableFeralGamemode = true;
        FallbackMRBlockedMods = 2;
        IconTheme = "pe_light";
        IgnoreJavaCompatibility = false;
        IgnoreJavaWizard = true;
        JavaPath = "${pkgs.openjdk}/bin/java";
        Language = "en_US";
        LaunchMaximized = false;
        LowMemWarning = true;
        MaxMemAlloc = 8192;
        MinMemAlloc = 4096;
        MinecraftWinHeight = 1440;
        MinecraftWinWidth = 2560;
        QuitAfterGameStop = true;
        ShowConsole = false;
        ShowConsoleOnError = true;
        UseNativeGLFW = false;
        UseNativeOpenAL = false;
        UseZink = true;
        UserAskedAboutAutomaticJavaDownload = true;
      };
    };
    ripgrep.enable = true;
    rofi = {
      enable = true;
      modes = [ "drun" ];
      terminal = terminal.command;
      font = "${font.mono.family} ${toString font.mono.size}";
      extraConfig = {
        drun-display-format = "{name}";
        display-drun = "drun: ";
      };
      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        configuration.show-icons = true;
        "*" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#ffffffd1";
        };
        "window" = {
          border-radius = mkLiteral "10px";
          padding = mkLiteral "10px";
          border = mkLiteral "2px";
          border-color = mkLiteral "#ffffffd1";
          background-color = mkLiteral "#000000b3";
        };
        "element".padding = mkLiteral "2px";
        "element-text selected".text-color = mkLiteral "#000000";
        "element-icon selected".text-color = mkLiteral "#000000";
        "element selected normal" = {
          background-color = mkLiteral "#ffffffd1";
          text-color = mkLiteral "#000000";
        };
      };
    };
    skim = {
      enable = true;
      enableZshIntegration = true;
    };
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".IdentityFile = [
        "${config.home.homeDirectory}/.ssh/id_ed25519_sk"
        "${config.home.homeDirectory}/.ssh/id_ed25519_sk_backup"
      ];
    };
    wezterm = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        color_scheme = "tokyonight_night";
        colors.background = "#000000";
        font = lib.generators.mkLuaInline ''wezterm.font("${font.mono.family}")'';
        font_size = font.mono.size;
        freetype_load_flags = "NO_HINTING"; # only keep this line if using unhinted font; else comment out
        hide_tab_bar_if_only_one_tab = true;
        window_padding = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
      };
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      settings = {
        preview.cache_dir = "${config.xdg.cacheHome}/yazi";
        mgr = {
          sort_by = "btime";
          sort_reverse = true;
          sort_dir_first = true;
        };
      };
      keymap.mgr.prepend_keymap = [
        {
          run = "cd ${config.home.homeDirectory}/Projects";
          desc = "Go to ~/Projects";
          on = [
            "g"
            "p"
          ];
        }
        {
          run = "cd ${config.home.homeDirectory}/Pictures";
          desc = "Go to ~/Pictures";
          on = [
            "g"
            "P"
          ];
        }
        {
          run = "cd ${config.home.homeDirectory}/Documents";
          desc = "Go to ~/Documents";
          on = [
            "g"
            "d"
          ];
        }
        {
          run = "cd ${config.home.homeDirectory}/Downloads";
          desc = "Go to ~/Downloads";
          on = [
            "g"
            "D"
          ];
        }
        {
          run = "cd /run/media/${config.home.username}";
          desc = "Go to media mounts";
          on = [
            "g"
            "m"
          ];
        }
        {
          run = ''shell --block -- umount "$0"'';
          desc = "Unmount highlighted directory";
          on = [
            "u"
            "m"
          ];
        }
        {
          run = ''shell -- ya emit cd "${config.home.homeDirectory}/Projects/vessel/$(hostname)"'';
          desc = "Go to this system's config";
          on = [
            "g"
            "s"
          ];
        }
        {
          run = "shell --block -- nh os switch ; echo '\nPress enter to exit\n' && read";
          desc = "Update this system";
          on = [
            "u"
            "s"
          ];
        }
        {
          run = "cd ${config.home.homeDirectory}/Projects/vessel/${config.home.username}";
          desc = "Go to this user's home config";
          on = [
            "g"
            "u"
          ];
        }
        {
          run = "shell --block -- nh home switch ; echo '\nPress enter to exit\n' && read";
          desc = "Update this user's home-manager";
          on = [
            "u"
            "h"
          ];
        }
      ];
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      initContent = lib.mkMerge [
        (lib.mkOrder 500 zsh.instantPrompt)
        (lib.mkOrder 550 zsh.pluginsAndConfig)
      ];
    };
  };
  services = {
    darkman = {
      enable = true;
      settings = {
        lat = 43.07468984247235;
        lng = -89.3841682686535;
        usegeoclue = false;
      };
      darkModeScripts.gtk = ''${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"'';
      lightModeScripts.gtk = ''${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"'';
    };
    dunst = {
      enable = true;
      settings = {
        global = {
          font = "${font.mono.family} ${toString font.mono.size}";
          width = "(128, 1024)";
          height = 128;
          origin = "top-right";
          offset = "10x10";
          padding = 15;
          horizontal_padding = 15;
          text_icon_padding = 10;
          frame_width = 3;
          frame_color = "ffffffd1";
          corner_radius = 10;
          background = "#000000b3";
          foreground = "#ffffff";
          transparency = 0;
          icon_position = "left";
          max_icon_size = 32;
          sort = true;
          layer = "overlay";
          show_indicators = false;
          stack_duplicates = true;
          sticky_history = true;
          ignore_dbusclose = true;
        };
        urgency_low.timeout = 0;
        urgency_normal.timeout = 0;
        urgency_critical.timeout = 0;
      };
    };
    hyprsunset = {
      enable = true;
      settings.profile = [
        {
          time = "06:00";
          identity = true;
        }
        {
          time = "22:30";
          temperature = 5500;
          gamma = 0.95;
        }
        {
          time = "00:00";
          temperature = 4000;
          gamma = 0.75;
        }
      ];
    };
    ollama = {
      enable = false;
      acceleration = "cuda";
      environmentVariables.OLLAMA_KEEP_ALIVE = "3m";
    };
    ssh-agent.enable = true;
    udiskie.enable = true;
  };
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-termfilechooser
      ];
      config = {
        common."org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        hyprland = {
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };
    configFile."xdg-desktop-portal-termfilechooser/config".text = let
      wrapper = pkgs.writers.writeDash "yazi-filechooser" ''
        set -e
        multiple="$1"
        directory="$2"
        save="$3"
        path="$4"
        out="$5"
        if [ "$save" = "1" ]; then
          set -- --chooser-file="$out" "$path"
        elif [ "$directory" = "1" ]; then
          set -- --chooser-file="$out" --cwd-file="$out".1 "$path"
        elif [ "$multiple" = "1" ]; then
          set -- --chooser-file="$out" "$path"
        else
          set -- --chooser-file="$out" "$path"
        fi
        fifo=$(mktemp -u /tmp/tfc-fifo.XXXXXX)
        mkfifo "$fifo"
        inner="yazi"
        for arg in "$@"; do
          escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
          inner="$inner \"$escaped\""
        done
        inner="$inner; echo x > \"$fifo\""
        ${pkgs.wezterm}/bin/wezterm start --always-new-process -- sh -c "$inner" &
        read _ < "$fifo"
        rm -f "$fifo"
        if [ "$directory" = "1" ]; then
          if [ ! -s "$out" ] && [ -s "$out".1 ]; then
            cat "$out".1 > "$out"
            rm "$out".1
          else
            rm -f "$out".1
          fi
        fi
      '';
    in ''
      [filechooser]
      cmd = ${wrapper}
      default_dir = ${config.home.homeDirectory}
      open_mode = suggested
      save_mode = suggested
      env = TERMCMD=${terminal.command}
      env = PATH=$PATH:${config.home.homeDirectory}/.local/state/nix/profile/bin:/run/current-system/sw/bin
    '';
    desktopEntries = {
      claude = {
        name = "Claude";
        exec = "chromium --app=https://claude.ai --name=claude";
        categories = [
          "Network"
          "Utility"
        ];
      };
      element = {
        name = "Element";
        exec = "chromium --app=https://app.element.io --name=element";
        icon = "element-desktop";
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "librewolf.desktop" ];
        "application/xhtml+xml" = [ "librewolf.desktop" ];
        "x-scheme-handler/http" = [ "librewolf.desktop" ];
        "x-scheme-handler/https" = [ "librewolf.desktop" ];
        "x-scheme-handler/about" = [ "librewolf.desktop" ];
        "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
        "image/bmp" = [ "imv.desktop" ];
        "image/tiff" = [ "imv.desktop" ];
        "image/svg+xml" = [ "imv.desktop" ];
        "image/*" = [ "imv.desktop" ];
        "audio/*" = [ "mpv.desktop" ];
        "video/*" = [ "mpv.desktop" ];
        "audio/mpeg" = [ "mpv.desktop" ];
        "audio/ogg" = [ "mpv.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "x-scheme-handler/terminal" = [ terminal.command ];
        "inode/directory" = [ "yazi.desktop" ];
        "application/x-directory" = [ "yazi.desktop" ];
        "text/plain" = [ "neovim.desktop" ];
        "text/*" = [ "neovim.desktop" ];
        "application/json" = [ "neovim.desktop" ];
        "application/xml" = [ "neovim.desktop" ];
        "application/pdf" = [ "libreoffice-writer.desktop" ];
        "application/msword" = [ "libreoffice-writer.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "libreoffice-writer.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "libreoffice-writer.desktop" ];
        "application/rtf" = [ "libreoffice-writer.desktop" ];
        "application/vnd.ms-excel" = [ "libreoffice-calc.desktop" ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "libreoffice-calc.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "libreoffice-calc.desktop" ];
        "text/csv" = [ "libreoffice-calc.desktop" ];
        "application/vnd.ms-powerpoint" = [ "libreoffice-impress.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "libreoffice-impress.desktop" ];
        "application/vnd.oasis.opendocument.presentation" = [ "libreoffice-impress.desktop" ];
      };
    };
  };
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings = let
      mod = "SUPER";
      mkLua = lib.generators.mkLuaInline;
      exec = cmd: mkLua "hl.dsp.exec_cmd(${builtins.toJSON cmd})";
      kb = keys: dsp: { _args = [ keys dsp ]; };
      kbf = keys: dsp: flags: { _args = [ keys dsp flags ]; };
      wsBinds = lib.concatMap (n:
        let k = toString (if n == 10 then 0 else n); in [
          (kb "${mod} + ${k}" (mkLua "hl.dsp.focus({ workspace = ${toString n} })"))
          (kb "${mod} + SHIFT + ${k}" (mkLua "hl.dsp.window.move({ workspace = ${toString n} })"))
        ]) (lib.range 1 10);
    in {
      monitor = {
        output = "DP-1";
        mode = "2560x1440@165";
        position = "0x0";
        scale = 1;
      };
      permission = [
        { _args = [ "${pkgs.grim}/bin/grim" "screencopy" "allow" ]; }
        { _args = [ "${pkgs.hyprlock}/bin/hyprlock" "screencopy" "allow" ]; }
        # { _args = [ "${pkgs.sunshine.override { cudaSupport = true; }}/bin/sunshine" "screencopy" "allow" ]; }
      ];
      config = {
        ecosystem = {
          no_update_news = true;
          enforce_permissions = true;
        };
        render = {
          cm_enabled = true;
          direct_scanout = true;
        };
        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          col.active_border = {
            colors = [ "rgba(ffffffdd)" "rgba(ffffffcc)" ];
            angle = 45;
          };
          col.inactive_border = "rgba(595959aa)";
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };
        decoration = {
          rounding = 10;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };
        animations.enabled = true;
        dwindle.preserve_split = true;
        master.new_status = "master";
        misc = {
          enable_anr_dialog = false;
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad.natural_scroll = false;
        };
        cursor = {
          inactive_timeout = 3;
          hide_on_key_press = true;
          no_hardware_cursors = true;
        };
      };
      curve = [
        { _args = [ "linear" { type = "bezier"; points = [ [ 0 0 ] [ 1 1 ] ]; } ]; }
        { _args = [ "easeOut" { type = "bezier"; points = [ [ 0.16 1 ] [ 0.3 1 ] ]; } ]; }
        { _args = [ "easeInOut" { type = "bezier"; points = [ [ 0.42 0 ] [ 0.58 1 ] ]; } ]; }
        { _args = [ "smoothOut" { type = "bezier"; points = [ [ 0.36 0 ] [ 0.66 (-0.56) ] ]; } ]; }
        { _args = [ "overshot" { type = "bezier"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; } ]; }
      ];
      animation = [
        { leaf = "fade"; enabled = true; speed = 4; bezier = "easeOut"; }
        { leaf = "fadeIn"; enabled = true; speed = 4; bezier = "easeOut"; }
        { leaf = "fadeOut"; enabled = true; speed = 3; bezier = "easeInOut"; }
        { leaf = "fadeDim"; enabled = true; speed = 4; bezier = "easeInOut"; }
        { leaf = "fadeShadow"; enabled = false; }
        { leaf = "windows"; enabled = true; speed = 4; bezier = "easeOut"; style = "slide"; }
        { leaf = "windowsIn"; enabled = true; speed = 4; bezier = "easeOut"; style = "popin 90%"; }
        { leaf = "windowsOut"; enabled = true; speed = 3; bezier = "easeInOut"; style = "popin 90%"; }
        { leaf = "windowsMove"; enabled = true; speed = 4; bezier = "easeOut"; }
        { leaf = "workspaces"; enabled = true; speed = 5; bezier = "easeOut"; style = "fade"; }
        { leaf = "border"; enabled = true; speed = 8; bezier = "easeOut"; }
        { leaf = "borderangle"; enabled = false; }
      ];
      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };
      workspace_rule = [
        { workspace = "w[tv1]"; gaps_out = 0; gaps_in = 0; }
        { workspace = "f[1]"; gaps_out = 0; gaps_in = 0; }
      ];
      window_rule = [
        { name = "no-gaps-wtv1"; match = { float = false; workspace = "w[tv1]"; }; border_size = 0; rounding = 0; }
        { name = "no-gaps-f1"; match = { float = false; workspace = "f[1]"; }; border_size = 0; rounding = 0; }
        { name = "suppress-maximize"; match = { class = ".*"; }; suppress_event = "maximize"; }
        { name = "no-focus-empty-xwayland"; match = { class = "^$"; title = "^$"; xwayland = true; float = true; fullscreen = false; }; no_focus = true; }
        { name = "scratchpad"; match = { title = "^(scratchpad)$"; }; float = true; size = [ "70%" "70%" ]; center = true; }
      ];
      on._args = [
        "hyprland.start"
        (mkLua ''
          function()
            hl.exec_cmd("awww-daemon")
            hl.exec_cmd("awww clear 000000")
            hl.exec_cmd("mv ${config.home.homeDirectory}/ly-session.log ${config.home.homeDirectory}/.ly-session.log")
          end'')
      ];
      bind = [
        (kb "${mod} + return" (exec terminal.command))
        (kb "${mod} + E" (exec "${terminal.command} zsh -c yazi"))
        (kb "${mod} + V" (exec "${terminal.command} zsh -c nvim"))
        (kb "${mod} + B" (exec "${terminal.command} zsh -c btm"))
        (kb "${mod} + P" (exec "keepassxc"))
        (kb "${mod} + G" (exec "steam"))
        (kb "${mod} + S" (exec "librewolf"))
        (kb "${mod} + ALT + S" (exec "chromium"))
        (kb "${mod} + M" (exec "chromium --app=https://app.element.io"))
        (kb "${mod} + C" (exec "chromium --app=https://claude.ai"))
        (kb "${mod} + ALT + M" (exec "${pkgs.signal-desktop}/bin/signal-desktop"))
        (kb "${mod} + N" (exec "${terminal.command} zsh -c 'nix run nixpkgs#qbittorrent'"))
        (kb "${mod} + T" (exec "${terminal.command} zsh -c 'nix run nixpkgs#tor-browser'"))
        (kb "${mod} + R" (exec "killall rofi || rofi -show drun"))
        (kb "${mod} + A" (exec "killall wiremix || ${terminal.command} wiremix"))
        (kb "${mod} + equal" (exec ''cfg=${config.home.homeDirectory}/.config/qalculate/qalc.cfg; caut=calculate_as_you_type; grep -q $caut $cfg 2>/dev/null || echo "$caut=1" >> $cfg; sed -i "s/.*$caut.*/$caut=1/" $cfg; ${terminal.command} qalc''))
        (kb "${mod} + D" (exec "dunstctl close"))
        (kb "${mod} + SHIFT + D" (exec "dunstctl close-all"))
        (kb "${mod} + minus" (exec "wl-copy -- —")) # em-dash
        (kb "${mod} + ALT + minus" (exec "wl-copy -- –")) # en-dash
        (kb "${mod} + I" (exec "wl-copy -- ∞"))
        (kb "${mod} + Q" (mkLua "hl.dsp.window.close()"))
        (kb "${mod} + F" (mkLua ''hl.dsp.window.float({ action = "toggle" })''))
        (kb "${mod} + Z" (mkLua ''hl.dsp.layout("togglesplit")''))
        (kb "${mod} + X" (mkLua "hl.dsp.window.swap({ prev = true })"))
        (kb "${mod} + backslash" (exec "hyprlock"))
        (kb "${mod} + CTRL + escape" (mkLua "hl.dsp.exit()"))
        (kb "print" (exec "hyprshot -m output -m active"))
        (kb "ALT + print" (exec "hyprshot -m window -m active"))
        (kb "CTRL + print" (exec "hyprshot -m region"))
        (kb "${mod} + H" (mkLua ''hl.dsp.focus({ direction = "left" })''))
        (kb "${mod} + J" (mkLua ''hl.dsp.focus({ direction = "down" })''))
        (kb "${mod} + K" (mkLua ''hl.dsp.focus({ direction = "up" })''))
        (kb "${mod} + L" (mkLua ''hl.dsp.focus({ direction = "right" })''))
        (kb "${mod} + left" (mkLua ''hl.dsp.focus({ direction = "left" })''))
        (kb "${mod} + up" (mkLua ''hl.dsp.focus({ direction = "up" })''))
        (kb "${mod} + down" (mkLua ''hl.dsp.focus({ direction = "down" })''))
        (kb "${mod} + right" (mkLua ''hl.dsp.focus({ direction = "right" })''))
        (kb "${mod} + grave" (mkLua ''hl.dsp.workspace.toggle_special("scratchpad")''))
        (kb "${mod} + mouse_down" (mkLua ''hl.dsp.focus({ workspace = "e+1" })''))
        (kb "${mod} + mouse_up" (mkLua ''hl.dsp.focus({ workspace = "e-1" })''))
        (kbf "${mod} + mouse:272" (mkLua "hl.dsp.window.drag()") { mouse = true; })
        (kbf "${mod} + mouse:273" (mkLua "hl.dsp.window.resize()") { mouse = true; })
        (kbf "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") { locked = true; repeating = true; })
        (kbf "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { locked = true; repeating = true; })
        (kbf "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { locked = true; repeating = true; })
        (kbf "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") { locked = true; repeating = true; })
        (kbf "XF86MonBrightnessUp" (exec "brightnessctl -e4 -n2 set 5%+") { locked = true; repeating = true; })
        (kbf "XF86MonBrightnessDown" (exec "brightnessctl -e4 -n2 set 5%-") { locked = true; repeating = true; })
        (kbf "XF86AudioNext" (exec "playerctl next") { locked = true; })
        (kbf "XF86AudioPause" (exec "playerctl play-pause") { locked = true; })
        (kbf "XF86AudioPlay" (exec "playerctl play-pause") { locked = true; })
        (kbf "XF86AudioPrev" (exec "playerctl previous") { locked = true; })
      ] ++ wsBinds;
    };
  };
}
