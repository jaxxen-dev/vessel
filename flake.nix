/* SPDX-License-Identifier: MIT
 * Copyright (C) 2026 Jaxxen
 */

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    age-plugin-fido2-rk = {
      url = "gitlab:nixipi/age-plugin-fido2-rk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ccvm = {
      url = "github:openccvm/ccvm";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        claude-code.follows = "claude-code";
      };
    };
    rycee-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    nixpkgs,
    disko,
    lanzaboote,
    impermanence,
    sops-nix,
    home-manager,
    age-plugin-fido2-rk,
    nixvim,
    claude-code,
    ccvm,
    ...
  }:
  let
    system = "x86_64-linux";
    overlays = [
      (_: _: { claude-code = claude-code.packages.${system}.default; })
      age-plugin-fido2-rk.overlays.default
    ];
    pkgs = import nixpkgs {
      inherit system overlays;
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude" ];
    };
    inherit (nixpkgs) lib;
  in {
    nixosConfigurations.iridium = lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        impermanence.nixosModules.impermanence
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        ./iridium/disks.nix
        ./iridium/hardware-configuration.nix
        ./iridium/configuration.nix
        {
          nixpkgs.overlays = overlays;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            extraSpecialArgs.addons = inputs.rycee-addons.packages.${system};
            sharedModules = [
              ccvm.homeModules.ccvm
              nixvim.homeModules.nixvim
            ];
            users.jaxxen = import ./jaxxen/home.nix;
          };
        }
      ];
    };
    devShells.${system}.default = import ./shell.nix {
      inherit pkgs;
      nixvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        module = { ... }: {
          imports = [ ./jaxxen/nixvim.nix ];
        };
      };
    };
  };
}
