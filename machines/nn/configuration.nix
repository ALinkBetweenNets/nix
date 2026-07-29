{ self, ... }:
{
  pkgs,
  lib,
  config,
  flake-self,
  home-manager,
  modulesPath,
  ...
}:
{
  imports = [
    home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
  ];
  home-manager.users.l = flake-self.homeConfigurations.server;
  system.autoUpgrade.enable = lib.mkForce false;
  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_580; # Older versions
  link = {
    common.enable = true;
    hardware.enable = true;
    server.enable = true;
    cpu-intel.enable = true;
    nvidia.enable = true;
    tailscale.enable = true;
    tailscale.routing = "server";
    fs.zfs.enable = true;
    fs.btrfs.enable = true;
    fs.luks.enable = true;
    nftables.enable = true;
    libvirt.enable = true;
    wg-link.enable = true;
    wg-link.address = "10.5.5.2/24";
    grub.enable = true;
    storage = "/z/srv";
    domain = "n.shonk.de";
    service-interface = "tailscale0";
    expose-ts = true;
    service-ports-expose = false;
    # nginx.enable = true;
    nginx-expose = false;
    # systemd-boot.enable = false;
    # fs.ntfs.enable = true;
    # vm.enable = true;
    # docker.enable = true;
    #   fail2ban.enable = true;
    # domain = "alinkbn.de";
    # storage = "/var/lib";
    syncthing.enable = true;
    syncthingDir = "/z/sync/";
    # secrets = "/pwd";
    # service-ip = "10.0.1.1";
    # users.lenny.enable = true;
    # users.lmh01.enable = true;
    # containers = {
    #   grist.enable = true;
    #   diagrams.enable = true;
    # };
    # zola.enable = true;
    podman.enable = true;
    # service-ports-expose = true;
    services = {
      #   radicale.enable = true;
      #   netbox.enable = true;
      #   # part-db.enable = true;
      #   # tt-rss.enable = true;
      #   # stirling-pdf.enable = true;
      #   # searx.enable = true;
      #   # cockpit.enable = true;
      #   microbin.enable = true;
      #   # mailserver.enable = true;
      #   cryptpad.enable = true;
      #   # photoprism.enable = true; # WIP
      #   # keycloak.enable = true;
      #   #gitea.enable = true;
      gitlab.enable = true;
      gitlab.storage = "/var/gitlab/state";
      #   onlyoffice.enable = true;
      #   # grafana.enable = true;
      #   # prometheus.enable = true;
      #   # # xandikos.enable = true; # WIP
      #   hedgedoc.enable = true;
      #   jellyfin.enable = true;
      #   # mealie.enable = true;
      #   # jellyseer.enable = true;
      #   minio.enable = true;
      immich.enable = true;
      #   audiobookshelf.enable = true;
      #   # openvscode-server.enable = true;
      #   nextcloud = {
      #     enable = true;
      #     nginx-expose = true;
      #   };
      #   vikunja.enable = true;
      #   # nfs.enable = true;
      #   # outline = {
      #   #   enable = true;
      #   #   # nginx-expose = true;
      #   #   oidClientId =
      #   #     "7cec0458291c1d98c37bce1ad62ea7b02790d7330f1ce5b6a25d9da95c6b3108";
      #   # };
      #   paperless.enable = true;
      #   # vaultwarden.enable = true;
      #   # # matrix.enable = true;
      restic-server.enable = true;
      restic-server.expose-port = true;
      #   # containers.grist.enable = true;
      #   # # coturn.enable = true;
      #   # # dns.enable = true;
      #   restic-client = {
      #     enable = true;
      #     backup-paths-lenny-storagebox = [
      #       "/var/lib/cryptpad"
      #       "/var/lib/gitlab/state/repositories"
      #       "/var/lib/hedgedoc"
      #       "/var/lib/immich/library"
      #       "/var/lib/immich/backups"
      #       "/var/lib/immich/postgres"
      #       "/var/lib/immich/profile"
      #       # "/var/lib/immich/upload"
      #       "/var/lib/nextcloud-data"
      #       "/var/lib/nextcloud/data"
      #       "/var/lib/paperless"
      #       "/var/lib/postgresql"
      #       # "/var/lib/syncthing-data/w"
      #       # "/var/lib/syncthing-data/doc"
      #       # "/var/lib/syncthing-data/sec"
      #       # "/var/lib/syncthing-data/Music"
      #     ];
      #     backup-paths-p4n = [
      #       "/home/l/.ssh"
      #       "/var/lib/cryptpad"
      #       "/var/lib/gitlab"
      #       "/var/lib/hedgedoc"
      #       "/var/lib/immich"
      #       "/var/lib/nextcloud-data"
      #       "/var/lib/nextcloud/data"
      #       "/var/lib/paperless"
      #       "/var/lib/postgresql"
      #       "/var/lib/syncthing-data"
      #     ];
      #   };
    };
    # # wg-link.enable = true;
    # # services.jitsi = {
    # #   enable = true;
    # #   expose = false;
    # # };
    eth = "enp6s0";
  };
  sops.defaultSopsFile = lib.mkForce ../../secrets/nn.yaml;
  # services.postgresql.dataDir = "${config.link.storage}/postgresql/${config.services.postgresql.package.psqlSchema}";
  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    loadModels = [
      "llama3.2"
      "qwen3"
      "nomic-embed-text"
      "starcoder2:3b"
    ];
  };
  powerManagement = {
    enable = true;
    #powertop.enable = true; # no option to disable usb powersaving yet
  };
  # services.owncast = {
  #   enable = true;
  #   openFirewall = true;
  #   listen = "0.0.0.0";
  #   rtmp-port = 1935;
  #   port = 8888;
  # };
  # services.onedrive.enable = true;
  # services.clamav = {
  #   # Antivirus
  #   daemon.enable = true;
  #   updater.enable = true;
  # };
  # users.users.root.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBu+WcpENdr7FaCIwj6WsinGnykIPV/tnIyrfEHSeU+E root@sn"
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1CM1Z6Q6qbzWhHiUlOtZ0UQjkCUBj6dg5YAik4sw4+ root@npn"
  # ];
  # services.cloudflare-dyndns = {
  #   ipv4 = lib.mkForce false;
  #   ipv6 = lib.mkForce false;
  # };
  # boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.interfaces."${config.link.eth}".allowedTCPPorts = [
    2522
  ];
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    config.link.services.immich.port
  ];
  networking = {
    nat = {
      enable = true;
      # Use "ve-*" when using nftables instead of iptables
      internalInterfaces = [ "ve-+" ];
      externalInterface = config.link.eth;
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };

    #   firewall = {
    #     # allowedUDPPorts = [ 51821 ];
    #     # allowedTCPPorts = [ 51821 ];
    #   };
    #   nat = {
    #     enable = true;
    #     externalInterface = "tailscale0";
    #     externalIP = "100.89.178.137";
    #     internalInterfaces = [ "virbr0" ];
    #     internalIPs = [ "192.168.122.91/32" ];
    #     forwardPorts = [
    #       # { sourcePort = 41623; proto = "tcp"; destination = "192.168.122.91:22"; loopbackIPs = [ "192.168.122.1" ]; }
    #     ];
    #   };
    #   interfaces."${config.link.eth}".wakeOnLan.enable = true;
    hostName = "nn";
    domain = "monitor-banfish.ts.net";
    hostId = "007f0200";
    #   extraHosts = ''
    #     192.168.122.200 snvnarr
    #   '';
  };
  # virtualisation.containers.enable = true;
  # containers.hedgedoc = {
  #   autoStart = true;
  #   privateNetwork = true;
  #   hostAddress = "192.168.100.1";
  #   localAddress = "192.168.100.11";
  #   hostAddress6 = "fc00::1";
  #   localAddress6 = "fc00::11";
  #   config =
  #     {
  #       config,
  #       pkgs,
  #       lib,
  #       ...
  #     }:
  #     {
  #       services.hedgedoc = {
  #         enable = true;
  #         # workDir = "${config.link.storage}/hedgedoc";
  #         settings = {
  #           #domain = "hedgedoc.${config.link.domain}";
  #           host = "0.0.0.0";
  #           port = 8080;
  #           # protocolUseSSL = true;
  #           # useSSL = false;
  #           # db = {
  #           #   dialect = "sqlite";
  #           #   storage = "/var/lib/hedgedoc/db.sqlite";
  #           # };
  #         };
  #       };
  #       # services.nextcloud = {
  #       #   enable = true;
  #       #   package = pkgs.nextcloud28;
  #       #   hostName = "localhost";
  #       #   config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # DON'T DO THIS IN PRODUCTION - the password file will be world-readable in the Nix Store!
  #       # };

  #       system.stateVersion = "25.11";

  #       networking = {
  #         firewall = {
  #           enable = true;
  #           allowedTCPPorts = [ 8080 ];
  #         };
  #         # Use systemd-resolved inside the container
  #         # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
  #         useHostResolvConf = lib.mkForce false;
  #       };

  #       services.resolved.enable = true;

  #     };

  # };
  # containers.gitlab = {
  #   autoStart = true;
  #   privateNetwork = true;
  #   hostAddress = "192.168.100.1";
  #   localAddress = "192.168.100.11";
  #   hostAddress6 = "fc00::1";
  #   localAddress6 = "fc00::11";
  #   config =
  #     {
  #       config,
  #       pkgs,
  #       lib,
  #       ...
  #     }:
  #     {
  #       services.hedgedoc = {
  #         enable = true;
  #         # workDir = "${config.link.storage}/hedgedoc";
  #         settings = {
  #           #domain = "hedgedoc.${config.link.domain}";
  #           host = "0.0.0.0";
  #           port = 8080;
  #           # protocolUseSSL = true;
  #           # useSSL = false;
  #           # db = {
  #           #   dialect = "sqlite";
  #           #   storage = "/var/lib/hedgedoc/db.sqlite";
  #           # };
  #         };
  #       };
  #       # services.nextcloud = {
  #       #   enable = true;
  #       #   package = pkgs.nextcloud28;
  #       #   hostName = "localhost";
  #       #   config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # DON'T DO THIS IN PRODUCTION - the password file will be world-readable in the Nix Store!
  #       # };

  #       system.stateVersion = "25.11";

  #       networking = {
  #         firewall = {
  #           enable = true;
  #           allowedTCPPorts = [ 8080 ];
  #         };
  #         # Use systemd-resolved inside the container
  #         # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
  #         useHostResolvConf = lib.mkForce false;
  #       };

  #       services.resolved.enable = true;

  #     };

  # };
  # containers.postgres = {
  #   autoStart = true;
  #   privateNetwork = true;
  #   hostAddress = "192.168.100.1";
  #   localAddress = "192.168.100.10";
  #   hostAddress6 = "fc00::1";
  #   localAddress6 = "fc00::10";
  #   config =
  #     {
  #       config,
  #       pkgs,
  #       lib,
  #       ...
  #     }:
  #     {
  #       services.postgresql = {
  #         enable = true;
  #         settings.port = 5432;
  #         settings = {
  #           log_connections = true;
  #           log_statement = "all";
  #           logging_collector = true;
  #           log_disconnections = true;
  #           log_destination = lib.mkForce "syslog";

  #         };
  #         initdbArgs = [
  #           "--data-checksums"
  #           # "--allow-group-access"
  #         ];
  #       };

  #       system.stateVersion = "25.11";

  #       networking = {
  #         firewall = {
  #           enable = true;
  #           allowedTCPPorts = [ 5432 ];
  #         };
  #         # Use systemd-resolved inside the container
  #         # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
  #         useHostResolvConf = lib.mkForce false;
  #       };

  #       services.resolved.enable = true;

  #     };

  # };
  # fileSystems."/home/lmh01/jellyfin-data" = {
  #   device = "/var/lib/jellyfin-data";
  #   options = [ "bind" ];
  # };
  # fileSystems."/rz/sftp/lmh01/arr" = {
  #   device = "/rz/arr/";
  #   options = [ "bind" ];
  # };
  # fileSystems."/var/lib/onedrive/restic" = {
  #   device = "/var/lib/restic";
  #   options = [
  #     "bind"
  #     "ro"
  #   ]; # read only, wouldnt want a onedrive mess up to be able to affect the main repo
  # };

  # environment.systemPackages = with pkgs; [
  #   rclone
  #   (
  #     let
  #       # XXX specify the postgresql package you'd like to upgrade to.
  #       # Do not forget to list the extensions you need.
  #       newPostgres = pkgs.postgresql_16.withPackages (pp: [
  #         # pp.plv8
  #       ]);
  #       cfg = config.services.postgresql;
  #     in
  #     pkgs.writeScriptBin "upgrade-pg-cluster" ''
  #       set -eux
  #       # XXX it's perhaps advisable to stop all services that depend on postgresql
  #       systemctl stop postgresql

  #       export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
  #       export NEWBIN="${newPostgres}/bin"

  #       export OLDDATA="${cfg.dataDir}"
  #       export OLDBIN="${cfg.finalPackage}/bin"

  #       install -d -m 0700 -o postgres -g postgres "$NEWDATA"
  #       cd "$NEWDATA"
  #       sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}

  #       sudo -u postgres "$NEWBIN/pg_upgrade" \
  #         --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
  #         --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
  #         "$@"
  #     ''
  #   )
  # ];

  # virtualisation.oci-containers.containers.librespeedtest = {
  #   autoStart = true;
  #   image = "adolfintel/speedtest";
  #   environment = {
  #     TITLE = "sn speedtest";
  #     ENABLE_ID_OBFUSCATION = "true";
  #     WEBPORT = "8766";
  #     MODE = "standalone";
  #   };
  #   ports = [ "8766:8766/tcp" ];
  # };
  # systemd.services.docker-librespeedtest = {
  #   preStop = "${pkgs.docker}/bin/docker kill librespeedtest";
  # };
  # powerManagement.powertop.enable = true;
  # virtualisation.sharedDirectories = {
  #   arr = {
  #     source = "/rz/arr";
  #     target = "/mnt/arr";
  #   };
  # };
  # services.onedrive.enable = true;
  # boot = {
  #   # loader.grub.device = "/dev/sdd";
  #   zfs.extraPools = [ "wdp" ];
  # };
  # Supress systemd units that don't work because of LXC.
  # https://blog.xirion.net/posts/nixos-proxmox-lxc/#configurationnix-tweak
  # systemd.suppressedSystemUnits = [
  #   "dev-mqueue.mount"
  #   "sys-kernel-debug.mount"
  #   "sys-fs-fuse-connections.mount"
  # ];
  system.stateVersion = "25.11";
}
