{
  description = "My NixOS infrastructure";
  inputs = {
    nix-index-database = {
      # xr-linux-flake.url = "github:alinkbetweennets/xr-linux-flake";
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nur.url = "github:nix-community/NUR";
    # Pure Nix flake utility functions
    # https://github.com/numtide/flake-utils
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm.url = "github:astro/microvm.nix";
    mobile-nixos = {
      url = "github:NixOS/mobile-nixos";
      # inputs.nixpkgs.follows = "nixpkgs";
      flake = false;
    };
    ucodenix.url = "github:e-tho/ucodenix";
    # vscode-server = {
    #   url = "github:msteen/nixos-vscode-server";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    crab_share = {
      url = "github:lounge-rocks/crab_share";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nsearch = {
      url = "github:niksingh710/nsearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bonn-mensa = {
      url = "github:alexanderwallau/bonn-mensa";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    zen-browser.url = "github:youwen5/zen-browser-flake";
    # ondsel = {
    #   url = "github:pinpox/ondsel-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    pwndbg = {
      url = "github:pwndbg/pwndbg";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Adblocking lists for Unbound DNS servers running on NixOS
    # https://github.com/MayNiklas/nixos-adblock-unbound
    adblock-unbound = {
      url = "github:MayNiklas/nixos-adblock-unbound";
      inputs = {
        adblockStevenBlack.follows = "adblockStevenBlack";
        nixpkgs.follows = "nixpkgs";
      };
    };
    # Adblocking lists for DNS servers
    # input here, so it will get updated by nix flake update
    adblockStevenBlack = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };
    mayniklas = {
      url = "github:MayNiklas/nixos";
      inputs = {
        disko.follows = "disko";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    grub2-themes = {
      url = "github:paulmiro/grub2-themes";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nur,
      nixgl,
      NixVirt,
      # simple-nixos-mailserver,
      ...
    }@inputs:
    with inputs;
    let
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
            nur.overlays.default
            nixgl.overlay
          ];
        }
      );
    in
    {
      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt);
      overlays.default = final: prev: (import ./pkgs inputs) final prev;
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          # displaylink=pkgs.displaylink;
          precomp = pkgs.link.precomp;
          woodpecker-pipeline = pkgs.callPackage ./pkgs/woodpecker-pipeline {
            flake-self = self;
            inputs = inputs;
          };

        }
      );
      apps = forAllSystems (system: { });
      # Output all modules in ./modules to flake. Modules should be in
      # individual subdirectories and contain a default.nix file
      nixosModules = builtins.listToAttrs (
        map (x: {
          name = x;
          #specialArgs = { flake-self = self; } // inputs;
          value = import (./modules + "/${x}");
        }) (builtins.attrNames (builtins.readDir ./modules))
      );
      # Each subdirectory in ./machines is a host. Add them all to
      # nixosConfiguratons. Host configurations need a file called
      # configuration.nix that will be read first
      nixosConfigurations =
        builtins.listToAttrs (
          map (x: {
            name = x;
            value = nixpkgs.lib.nixosSystem {
              # Make inputs and the flake itself accessible as module parameters.
              # Technically, adding the inputs is redundant as they can be also
              # accessed with flake-self.inputs.X, but adding them individually
              # allows to only pass what is needed to each module.
              specialArgs = {
                flake-self = self;
              }
              // inputs;
              modules = builtins.attrValues self.nixosModules ++ [
                #inputs.nixos-facter-modules.nixosModules.facter
                (import "${./.}/machines/${x}/configuration.nix" {
                  inherit self;
                  #config.facter.reportPath = ./facter.json;
                })
                disko.nixosModules.disko
                sops-nix.nixosModules.sops
                grub2-themes.nixosModules.default
                # simple-nixos-mailserver.nixosModules
                # ({ config, ... }: {
                #   # shut up state version warning
                #   system.stateVersion = config.system.nixos.version;
                #   # Adjust this to your liking.
                #   # WARNING: if you set a too low value the image might be not big enough to contain the nixos installation
                #   disko.devices.disk.vdb.imageSize = "10G";
                # })
              ];
            };
          }) (builtins.filter (dirName: dirName != "pppn") (builtins.attrNames (builtins.readDir ./machines)))
        )
        // {

          # specify pppn seperately since it relies on system being set
          pppn = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = {
              flake-self = self;
            }
            // inputs;
            modules = builtins.attrValues self.nixosModules ++ [
              "${mobile-nixos}/examples/phosh/phosh.nix"
              (import "${mobile-nixos}/lib/configuration.nix" {
                device = "pine64-pinephonepro";
              })
              (import "${./.}/machines/pppn/configuration.nix" {
                inherit self;
              })
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
            ];
          };

        };
      homeConfigurations = builtins.listToAttrs (
        map (filename: {
          name = builtins.substring 0 ((builtins.stringLength filename) - 4) filename;
          value =
            {
              pkgs,
              lib,
              username,
              ...
            }:
            {
              # extraSpecialArgs =  { inherit xr-linux-flake; };
              imports = [
                "${./.}/home-manager/profiles/common.nix"
                "${./.}/home-manager/profiles/${filename}"
              ]
              ++ (builtins.attrValues self.homeModules);
            };
        }) (builtins.attrNames (builtins.readDir ./home-manager/profiles))
      );
      homeModules =
        builtins.listToAttrs (
          map (name: {
            inherit name;
            value = import (./home-manager/modules + "/${name}");
          }) (builtins.attrNames (builtins.readDir ./home-manager/modules))
        )
        // {
          # This module is appended to the list of home-manager modules.
          # It's always enabled for all profiles.
          # It's used to easily add overlays and imports to home-manager.
          # Since this module is within this flake.nix, it will access our flake inputs.
          nix =
            { pkgs, ... }:
            {
              # import home manager modules from this flake
              imports = [
                inputs.nvf.homeManagerModules.default
                inputs.plasma-manager.homeModules.plasma-manager
                # inputs.vscode-server.nixosModules.home
              ];
              # add overlays from this flake
              nixpkgs.overlays = [
                self.overlays.default
                inputs.crab_share.overlay
                inputs.nur.overlays.default
                # (final: prev: {
                #   displaylink = prev.displaylink.overrideAttrs  {
                #     src = prev.fetchurl {
                #       url =
                #         "https://www.synaptics.com/sites/default/files/exe_files/2024-10/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.1-EXE.zip";
                #       # either pre‑run `nix-prefetch-url URL` to get this sha256,
                #       # or let Nix error and copy the “got: sha256-…” it prints.
                #       sha256 = "0RJgVrX+Y8Nvz106Xh+W9N9uRLC2VO00fBJeS8vs7fKw=";
                #     };
                #   };
                # })
                (final: prev: {
                  cudapkgs = import inputs.nixpkgs {
                    system = "${pkgs.stdenv.hostPlatform.system}";
                    config = {
                      allowUnfree = true;
                      cudaSupport = true;
                    };
                  };
                })
              ];
              # Visual Studio Code Server support
              # services.vscode-server = {
              #   enable = true;
              #   installPath = "~/.vscode-server";
              # };
            };
        };
      devShells = forAllSystems (
        system: with nixpkgsFor.${system}; {
          default = pkgs.mkShell {
            packages = [

            ];
          };
        }
      );
      checks =
        let
          hostsForSystem =
            system: names:
            nixpkgs.lib.genAttrs names (name: self.nixosConfigurations.${name}.config.system.build.toplevel);
        in
        {
          aarch64-linux = hostsForSystem "aarch64-linux" [
            "p4n"
          ];
          x86_64-linux = hostsForSystem "x86_64-linux" [
            "fn"
            "fnvn"
            "xn"
            "nn"
            "sn"
            "nc"
            "vn"
          ];
        };
      # colmena = {
      #   meta = {
      #     nixpkgs = import nixpkgs {
      #       system = "x86_64-linux";
      #     };
      #   };
      #   hosts = self.nixosConfigurations;
      # };
    };
}
