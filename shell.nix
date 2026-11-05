/* SPDX-License-Identifier: MIT
 * Copyright (C) 2026 Jaxxen
 */

{
  pkgs,
  nixvim,
  ...
}:
let
  zsh = import ./jaxxen/zsh.nix {
    inherit pkgs;
  };
  utils = import ./jaxxen/utils.nix {
    inherit pkgs;
  };
in pkgs.mkShell {
  packages = [ nixvim ] ++ zsh.packages ++ utils;
  shellHook = ''
    export ZDOTDIR=$(mktemp -d)
    cat > $ZDOTDIR/.zshrc << 'EOF'
    ${zsh.instantPrompt}
    ${zsh.pluginsAndConfig}
    EOF
    exec zsh
  '';
}
