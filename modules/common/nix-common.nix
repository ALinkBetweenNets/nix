{ lib, pkgs, config, nixpkgs, flake-self, home-manager, ... }: {
  system = {
    activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        if [[ -e /run/current-system ]]; then
          echo "--- diff to current-system"
          ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
          echo "---"
        fi
      '';
    };
    autoUpgrade = {
      enable = false;
      allowReboot = true;
      rebootWindow = {
        lower = "05:00";
        upper = "07:00";
      };
      randomizedDelaySec = "45min";
      persistent = true;
      flake = "github:alinkbetweennets/nix";
      flags = [ "-L" ];
    };
    # stateVersion = "23.11";
  };
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {
      inherit flake-self;
      # Pass system configuration (top-level "config") to home-manager modules,
      # so we can access it's values for conditional statements
      system-config = config;
    };
  };
  programs.nix-ld.enable = true;
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/home/l/.ssh/id_ed25519" ];
    secrets = { };
    templates = { };
  };
  # Home Manager configuration
  # Allow unfree licenced packages
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      flake-self.overlays.default
      flake-self.inputs.nur.overlays.default
      flake-self.inputs.crab_share.overlay
      # (final: prev: {
      #   ondsel = flake-self.inputs.ondsel.packages.${pkgs.stdenv.hostPlatform.system}.ondsel;
      # })
      (final: prev: {
        cudapkgs = import flake-self.inputs.nixpkgs {
          system = "${pkgs.stdenv.hostPlatform.system}";
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
      })
    ];
  };
  nix = {
    # Set the $NIX_PATH entry for nixpkgs. This is necessary in
    # this setup with flakes, otherwise commands like `nix-shell
    # -p pkgs.htop` will keep using an old version of nixpkgs.
    # With this entry in $NIX_PATH it is possible (and
    # recommended) to remove the `nixos` channel for both users
    # and root e.g. `nix-channel --remove nixos`. `nix-channel
    # --list` should be empty for all users afterwards
    nixPath = [ "nixpkgs=${nixpkgs}" ];
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      # If set to true, Nix will fall back to building from source if a binary substitute fails.
      fallback = true
      # the timeout (in seconds) for establishing connections in the binary cache substituter.
      connect-timeout = 10
      # these log lines are only shown on a failed build
      log-lines = 25
    '';
    settings = {
      # binary cache -> build by DroneCI
      substituters = [
        "https://cache.lounge.rocks/nix-cache"
        "https://ai.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://numtide.cachix.org"
        "https://pwndbg.cachix.org"
      ];
      trusted-public-keys = [
        "nix-cache:4FILs79Adxn/798F8qk2PC1U8HaTlaPqptwNJrXNA1g="
        "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "pwndbg.cachix.org-1:HhtIpP7j73SnuzLgobqqa8LVTng5Qi36sQtNt79cD3k="
      ];
      # Enable flakes
      experimental-features = [ "nix-command" "flakes" ];
      # Save space by hardlinking store files
      auto-optimise-store = true;
    };
    optimise.automatic = true;
    gc = {
      persistent = false;
      automatic = true;
      options = "--delete-older-than 14d";
    };
  };
}
