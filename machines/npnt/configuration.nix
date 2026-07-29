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
  link = {
    podman.enable = true;
    common.enable = true;
    server.enable = true;
    # wg-link.enable = true;
    # wg-link.address = "10.5.5.6/24";
    fs.luks.enable = true;
    # grub.enable = true;
    # systemd-boot.enable = false;
    # fs.zfs.enable = true;
    # fs.btrfs.enable = true;
    # fs.luks.enable = true;
    # fs.ntfs.enable = true;
    vm.enable = true;
    cpu-intel.enable = true;
    # docker.enable = true;
    fail2ban.enable = true;
    domain = "alinkbn.de";
    # domain = "alinkbn.de";
    storage = "/hdd";
    # syncthingDir = "/var/lib/syncthing";
    # secrets = "/pwd";
    # service-ip = "10.0.1.1";
    # users.lenny.enable = true;
    # users.lmh01.enable = true;
    service-interface = "tailscale0";
    nginx.enable = false;
    nginx-expose = false;
    eth = "ens18";
    # containers = {
    #   grist.enable = true;
    #   diagrams.enable = true;
    # };
    # zola.enable = true;
    # syncthing.enable = true;
    service-ports-expose = true;
    services = {
      # ollama.enable = true;
      # ollama.expose-port = true;
      # keycloak.enable = true;
      # grafana.enable = true;
      # prometheus.enable = true;
      # immich.enable = true;
      # restic-server.enable = true;
      # nextcloud = {
      #   enable = false;
      #   nginx-expose = true;
      # };
      # paperless.enable = true;

      #   # tt-rss.enable = true;
      #   stirling-pdf.enable = true;
      # searx.enable = true;
      #   cockpit.enable = true;
      #   microbin.enable = true;
      #   # mailserver.enable = true;
      #   cryptpad.enable = true;
      #   #gitea.enable = true;
      #   gitlab.enable = true;
      #   # grafana.enable = true;
      #   # # xandikos.enable = true; # WIP
      #   # hedgedoc.enable = true;
      #   jellyfin.enable = true;
      #   mealie.enable = true;
      #   # jellyseer.enable = true;
      #   minio.enable = true;
      #   audiobookshelf.enable = true;
      #   # openvscode-server.enable = true;
      #   vikunja.enable = true;
      #   # nfs.enable = true;
      #   # outline = {
      #   #   enable = true;
      #   #   # nginx-expose = true;
      #   #   oidClientId =
      #   #     "7cec0458291c1d98c37bce1ad62ea7b02790d7330f1ce5b6a25d9da95c6b3108";
      #   # };
      #   # vaultwarden.enable = true;
      #   # # matrix.enable = true;
      #   restic-server.enable = true;
      #   # containers.grist.enable = true;
      #   # # coturn.enable = true;
      #   # # dns.enable = true;
      #   restic-client = {
      #     enable = true;
      #     backup-paths-lenny-storagebox = [
      #       "/var/lib/cryptpad"
      #       "/var/lib/gitlab"
      #       "/var/lib/hedgedoc"
      #       "/var/lib/immich"
      #       "/var/lib/nextcloud-data"
      #       "/var/lib/paperless"
      #       "/var/lib/postgresql"
      #       "/var/lib/syncthing-data/w"
      #       "/var/lib/syncthing-data/doc"
      #       "/var/lib/syncthing-data/sec"
      #       "/var/lib/syncthing-data/Music"
      #     ];
      #     backup-paths-p4n = [
      #       "/home/l/.ssh"
      #       "/var/lib/cryptpad"
      #       "/var/lib/gitlab"
      #       "/var/lib/hedgedoc"
      #       "/var/lib/immich"
      #       "/var/lib/nextcloud-data"
      #       "/var/lib/paperless"
      #       "/var/lib/postgresql"
      #       "/var/lib/syncthing-data"
      #     ];
      #   };
    };
    # wg-link.enable = true;
    # services.jitsi = {
    #   enable = true;
    #   expose = false;
    # };
  };

  services.spice-vdagentd.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  boot.kernelModules = [ "virtio_gpu" ];

  services.postgresql.dataDir = "${config.link.storage}/postgresql/${config.services.postgresql.package.psqlSchema}";
  # services.ollama = {
  #   enable = true;
  #   port = 11434;
  #   host = "0.0.0.0";
  #   loadModels = [ "llama3.1:70b" "nomic-embed-text" "starcoder2:3b" ];
  # };
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
  # services.cloudflare-dyndns = {
  #   ipv4 = lib.mkForce false;
  #   ipv6 = lib.mkForce false;
  # };
  # boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking = {
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
    hostName = "npnt";
    domain = "monitor-banfish.ts.net";
    hostId = "007f0200";
    #   extraHosts = ''
    #     192.168.122.200 snvnarr
    #   '';
  };
  services.nextcloud.hostName = lib.mkForce config.networking.fqdn;
  # services.postgresql =  {
  #     enable = true;
  #     # ensureDatabases = mkIf cfg.database.createDB [ cfg.database.name ];
  #     # ensureUsers = mkIf cfg.database.createDB [
  #     #   {
  #     #     name = cfg.database.user;
  #     #     ensureDBOwnership = true;
  #     #     ensureClauses.login = true;
  #     #   }
  #     # ];
  #     extensions = ps: with ps; [ pgvecto-rs ];
  #     settings = {
  #       shared_preload_libraries = [ "vectors.so" ];
  #       search_path = "\"$user\", public, vectors";
  #     };
  #   };
  environment.systemPackages = with pkgs; [
    rclone
    # (
    #   let
    #     # XXX specify the postgresql package you'd like to upgrade to.
    #     # Do not forget to list the extensions you need.
    #     newPostgres = pkgs.postgresql_16.withPackages (pp: [
    #       # pp.plv8
    #       pp.pgvecto-rs
    #     ]);
    #     cfg = config.services.postgresql;
    #   in
    #   pkgs.writeScriptBin "upgrade-pg-cluster" ''
    #     set -eux
    #     # XXX it's perhaps advisable to stop all services that depend on postgresql
    #     systemctl stop postgresql

    #     export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
    #     export NEWBIN="${newPostgres}/bin"

    #     export OLDDATA="${cfg.dataDir}"
    #     export OLDBIN="${cfg.finalPackage}/bin"

    #     install -d -m 0700 -o postgres -g postgres "$NEWDATA"
    #     cd "$NEWDATA"
    #     sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}

    #     sudo -u postgres "$NEWBIN/pg_upgrade" \
    #       --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
    #       --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
    #       "$@"
    #   ''
    # )
  ];

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
}
