{
  lib,
  system-config,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.link.fs.luks;
in
{
  options.link.fs.luks.enable = mkEnableOption "activate luks";
  # ONLY ENABLE ONCE "/etc/secrets/initrd/id_ed25519" exists
  # sudo mkdir -p /etc/secrets/initrd && sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/id_ed25519
  config = mkIf cfg.enable {
    # systemd.tmpfiles.rules = [ "d /etc/secrets/initrd 0600 root root" ];
    # systemd.tmpfiles.settings = {
    #   "10-initrd-secrets" = {
    #     "/etc/secrets/initrd" = {
    #       d = {
    #         mode = "0700";
    #         user = "root";
    #         group = "root";
    #       };
    #     };
    #   };
    # };
    services.openssh.hostKeys = [
      {
        path = "/etc/ssh/initrd_id_ed25519";
        rounds = 200;
        type = "ed25519";
      }
    ];
    # EVERYTHING BELOW THIS MUST BE UNCOMMENTED AND REBUILT ONCE FOR THE KEY GENERATION
    boot = {
      kernelParams = [ "ip=dhcp" ];
      ## This enables initrd to run a ssh server for entering the password for luks decryption
      initrd = {
        # secrets = {
        #   "/etc/secrets/initrd/ed25519.key" = /etc/secrets/initrd/ed25519.key;
        # };
        # supportedFilesystems = { btrfs=true; };
        network = {
          # netdevs."30-wg-initrd" = {
          #   netdevConfig = {
          #     Kind = "wireguard";
          #     Name = "wg-initrd";
          #   };
          #   wireguardConfig = {
          #     PrivateKeyFile = "/etc/secrets/30-wg-initrd.key";
          #   };
          #   wireguardPeers = [
          #     {
          #       AllowedIPs = [ "10.250.0.1/32" ];
          #       PublicKey = "wUE//Lwi8DZVIvAjIAtMoy+ku+hJ0w28H7ofySwAJRk=";
          #       Endpoint = "198.51.100.1:51821";
          #       PersistentKeepalive = 25;
          #     }
          #   ];
          # };
          # networks."30-wg-initrd" = {
          #   name = "wg-initrd";
          #   addresses = [ { Address = "10.250.0.2/24"; } ];
          # };
          enable = true;
          flushBeforeStage2 = true;
          # udhcpc.enable = true;
          # postCommands = mkIf (config.nixpkgs.hostPlatform == "x86_64-linux") ''
          #   # Automatically ask for the password on SSH login
          #   echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
          # '';
          ssh = {
            enable = true;
            port = 25222;
            shell = lib.mkForce "/bin/systemctl default";
            hostKeys = [ /etc/initrd_id_ed25519 ];
            # authorizedKeys = [
            #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOaLOyxsr6wgj0JoG/OrDywND2hG2nblOGUuZBPFG1U l@xn"
            #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINI74luZ3xJcgaZYHzn5DtSpYufml+SbhZQV12gWGShS l@dn"
            #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIj1OASl4OePBngiPlI4hixiD1GBlPOSoVNeoEcD23d+ l@fn"
            # ];

          };
        };
        availableKernelModules = [ "r8169" ]; # should work for most network hardware
      };
    };
  };
}
