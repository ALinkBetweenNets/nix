{
  lib,
  pkgs,
  flake-self,
  system-config,
  ...
}:
with lib;
{
  options.link.options = {
    type = mkOption {
      type = types.enum [
        "desktop"
        "laptop"
        "server"
      ];
      default = system-config.link.options.type;
      example = "server";
    };
  };
  imports = with flake-self.homeModules; [
    neovim
    shell
    git
  ];
  config = {
    home.sessionVariables = {
      EDITOR = "nvim";
    };
    home.homeDirectory = "/home/l";
    services.gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
    };
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "nc" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "nn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "sn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "dn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "xn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "p4n" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "pppn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "np" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "npn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "fn" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "10.5.5.1" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "10.5.5.5" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "10.5.5.6" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "c" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "f" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "n" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "s" = {
          port = 2522;
          identityFile = "~/.ssh/id_ed25519";
        };
        "*" = {
          compression = true;
          forwardAgent = false;
          addKeysToAgent = "no";
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      };

    };
    home.packages =
      with pkgs;
      [
        xcp
        dysk
        git-crypt
        yazi # TUI File Manager with preview
        nix-output-monitor
        gpg-tui
        tealdeer
        # fastfetch
        # tldr
        #home-manager
        ## security
        sops
        ssh-to-age
        bitwarden-cli
        ## piping
        # vgrep
        ## basics
        ## networking
        # iptables
        # nftables
        ## Networking+
        ipfetch
        # magic-wormhole # Secure data transfer
        # iperf3 # speedtest
        crab_share
        jdupes # duplicate Finder, better fdupes
        rmlint
      ]
      ++ lib.optionals (system-config.nixpkgs.hostPlatform.system == "x86_64-linux") [ ];
    # Home-manager nixpkgs config
    nixpkgs = {
      # Allow "unfree" licenced packages
      config.allowUnfree = true;
      overlays = [
        flake-self.overlays.default
        flake-self.inputs.bonn-mensa.overlays.default
      ];
    };
    home = {
      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      stateVersion = "23.11";
    };
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
