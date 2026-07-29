{
  config,
  system-config,
  pkgs,
  lib,
  nix-index-database,
  ...
}:
with lib;
let
  cfg = config.link.common;
in
{
  imports = [ nix-index-database.nixosModules.nix-index ];
  options.link.common.enable = mkEnableOption "activate common";
  config = mkIf cfg.enable {
    programs = {
      ssh = {
        startAgent = lib.mkDefault false;
      };
      nh = {
        enable = true;
        flake = "/home/l/nix/";
      };
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        # pinentryFlavor = if config.link.plasma.enable then "qt" else "gnome3";
      };
    };
    environment.shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
    # Does not seem to work
    # services.tlp.settings = {
    #   USB_AUTOSUSPEND = 0;
    # };
    environment.pathsToLink = [
      "/share/zsh"
      # "/share/fish"
    ];
    systemd.services.decrypt-sops = lib.mkIf link.sops{
      description = "Decrypt sops secrets";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # in network is not ready
        Restart = "on-failure";
        RestartSec = "2s";
      };
      script = config.system.activationScripts.setupSecrets.text;
    };
    link = {
      users = {
        l.enable = true;
        root.enable = true;
      };
      # systemd-boot.enable = lib.mkDefault true;
      openssh.enable = lib.mkDefault true;
      # nftables.enable = lib.mkDefault true;
      # fail2ban.enable = lib.mkDefault true;
    };
    # services.postgresql.package = pkgs.postgresql_17; # prevent major upgrades
    security = {
      sudo.wheelNeedsPassword = lib.mkDefault false;
      # polkit = {
      #   enable = true;
      #   adminIdentities = [ "unix-user:l" "unix-user:root" ];
      # };
      # apparmor.enable = true;
      # security.tpm2.enable = true;
      # security.tpm2.abrmd.enable = true;
      # auditd.enable = true;
    };
    # services.connman.wifi.backend = "iwd";
    networking = {
      #   networkmanager.wifi.backend = "iwd";
      #   wireless.iwd = {
      #     enable = true;
      #     settings = {
      #       General.EnableNetworkConfiguration = true;
      #       Settings.AutoConnect = true;
      #       Network.EnableIPv6 = true;
      #     };
      #   };
      firewall = {
        enable = lib.mkDefault true;
        pingLimit =
          if config.networking.nftables.enable then
            "1/minute burst 5 packets"
          else
            "--limit 1/minute --limit-burst 5";
        extraPackages = with pkgs; [ ipset ];
        allowedUDPPorts = [
          51820 # wireguard
          # 53 # dnsmasq
          # 1194 # vpn
          # 1195 # vpn
          # 1196 # vpn
          # 1197 # vpn
          # 1300 # vpn # are you sure about those?
          # 1301 # vpn
          # 1302 # vpn
          # 1303 # vpn
          # 1400 # vpn
        ];
        allowedTCPPorts = [
          # 53 # dnsmasq
          # 80 # vpn
          # 443 # vpn
          # 1401 # vpn
        ];
      };
    };
    # Use nix-index-database for comma
    programs.nix-index-database.comma.enable = true;
    environment.systemPackages =
      with pkgs;
      [
        ## system
        openssl
        limitcpu
        nix-fast-build
        unixtools.net-tools
        exfatprogs
        libsecret
        gnupg
        ## top
        s-tui
        nethogs
        busybox
        kmod # modprobe
        ## basics
        file
        killall
        trashy
        tmux
        zellij
        ## encryption& filesystem
        cryptsetup
        gocryptfs
        # cryfs
        age
        ## Network tools
        wget
        curl
        tree
        ## FS Tools
        # unzip
        # gnutar
        # xz
        # bzip2
        p7zip
        # netcat
        # netcat-gnu
        fzf
        gnugrep
        unixtools.watch
        wireguard-tools
        dnsutils
        fd
        ncdu # disk usage
        sysz
        systemctl-tui
        eza
        bat
        btop
        ccze
      ]
      ++ lib.optionals (config.nixpkgs.hostPlatform.system == "x86_64-linux") [ glances ];
    # console.font = "FiraCode Nerd Font";
    #   system.replaceRuntimeDependencies =
    #   let
    #     fixed-xz = (import
    #       (builtins.fetchGit {
    #         name = "xz-5-4-4";
    #         url = "https://github.com/NixOS/nixpkgs/";
    #         ref = "refs/heads/nixpkgs-unstable";
    #         rev = "9957cd48326fe8dbd52fdc50dd2502307f188b0d";
    #       })
    #       { system = "${pkgs.stdenv.hostPlatform.system}"; }).xz;
    #   in
    #   [
    #     ({
    #       original = pkgs.xz;
    #       replacement = fixed-xz;
    #     })
    #   ];
  };
}
