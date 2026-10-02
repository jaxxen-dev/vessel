{
  pkgs,
  ...
}:
let

  # start audio

  channel = "nixos-26.05";

  lofiDefault = { label = "lofi";        url = "https://www.youtube.com/watch?v=rFZHOHl-L8A"; };

  lofiCases = [
    { name = "summer"; label = "lofi summer"; url = "https://www.youtube.com/watch?v=0muHFBSiybw"; }
    { name = "fall";   label = "lofi fall";   url = "https://www.youtube.com/watch?v=8gJ716dhStg"; }
    { name = "sleep";  label = "lofi sleep";  url = "https://www.youtube.com/watch?v=VAlMDl00mYY"; }
    { name = "jazz";   label = "lofi jazz";   url = "https://www.youtube.com/watch?v=A8jDx9TLMQc"; }
  ];

  mkCase = { name, label, url }:
    "${name}) label='${label}'; url='${url}' ;;";

  cases = builtins.concatStringsSep "\n        " (map mkCase lofiCases);

  nixShell = ''nix shell "github:NixOS/nixpkgs/${channel}#streamlink" "github:NixOS/nixpkgs/${channel}#mpv"'';

  streamlinkCmd = ''--command bash -c 'streamlink --quiet --player "$(which mpv)" --player-args "--no-video --really-quiet" "$1" best' -- '';

  displayLabel = ''
    local cols=$(tput cols)
    local lines=$(tput lines)
    local hpad=$(( (cols - ''${#label}) / 2 ))
    local vpad=$(( (lines - 1) / 2 ))
    clear
    printf "%''${vpad}s" "" | tr ' ' '\n'
    printf "%''${hpad}s" ""
    printf '\e[1;3m%s\e[0m\n' "$label"
  '';

  mkFunc = name: body: ''
    ${name}() {
      ${body}
    }
  '';

  lofiFunc = mkFunc "lofi" ''
    local label url

    case "''${1:-}" in
      ${cases}
      *) label='${lofiDefault.label}'; url='${lofiDefault.url}' ;;
    esac

    ${displayLabel}
    ${nixShell} ${streamlinkCmd}"$url" 2>/dev/null
  '';

  oceanFunc = mkFunc "ocean" ''
    local label="ocean"
    ${displayLabel}
    ${nixShell} ${streamlinkCmd}"https://www.youtube.com/watch?v=vPhg6sc1Mk4" 2>/dev/null
  '';

  # end audio

  instantPrompt = ''
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi
  '';
  pluginsAndConfig = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    () {
      emulate -L zsh -o extended_glob
      unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
      [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return
      local grey='242'
      local red='#FF5C57'
      local yellow='#F3F99D'
      local blue='#57C7FF'
      local magenta='#FF6AC1'
      local cyan='#9AEDFE'
      local white='#F1F1F0'
      typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
      typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time virtualenv context time newline)
      typeset -g POWERLEVEL9K_BACKGROUND=
      typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
      typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
      typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
      typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
      typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
      typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
      typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
      typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
      typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
      typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
      typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false
      typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
      typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
      typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
      typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
      typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE=\"%F{$white}%n%f%F{$grey}@%m%f\"
      typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE=\"%F{$grey}%n@%m%f\"
      typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
      typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=5
      typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
      typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
      typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
      typeset -g POWERLEVEL9K_VCS_FOREGROUND=$grey
      typeset -g POWERLEVEL9K_VCS_LOADING_TEXT=
      typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0
      typeset -g POWERLEVEL9K_VCS_{INCOMING,OUTGOING}_CHANGESFORMAT_FOREGROUND=$cyan
      typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind)
      typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
      typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
      typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED}_ICON=
      typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='*'
      typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=':⇣'
      typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=':⇡'
      typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=1
      typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION=''${''${''${P9K_CONTENT/⇣* :⇡/⇣⇡}// }//:/ }
      typeset -g POWERLEVEL9K_TIME_FOREGROUND=$grey
      typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
      typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false
      typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
      typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
      (( ! $+functions[p10k] )) || p10k reload
    }
    ${lofiFunc}
    ${oceanFunc}
  '';
in {
  inherit instantPrompt pluginsAndConfig;
  packages = with pkgs; [
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
