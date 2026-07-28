{
  config,
  system-config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.link.services.gitlab;
in
{
  options.link.services.gitlab = {
    enable = mkEnableOption "activate gitlab";
    expose-lan = mkOption {
      type = types.bool;
      default = config.link.expose-lan;
      description = "directly expose the port of the application";
    };
    expose-ts = mkOption {
      type = types.bool;
      default = config.link.expose-ts;
      description = "directly expose the port of the application";
    };
    expose-nginx = mkOption {
      type = types.bool;
      default = config.link.expose-nginx-public;
      description = "directly expose the port of the application";
    };
    port = mkOption {
      type = types.int;
      default = 80;
      description = "port to run the application on";
    };
    storage = mkOption {
      type = types.str;
      description = "Storage for Gitlab State";
      default = "${config.link.storage}/gitlab/state";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets = {
      "gitlab/db" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/dbPass" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/otp" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/initialRoot" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/jws" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/secret" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/runner-default" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/runner-nix" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/runner-protected" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/activeRecordPrimary" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/activeRecordDeterministic" = {
        owner = "gitlab";
        group = "gitlab";
      };
      "gitlab/activeRecordSalt" = {
        owner = "gitlab";
        group = "gitlab";
      };
    };
    services = {
      nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts."gitlab.${config.link.domain}" = lib.mkIf (config.link.domain != "") {
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
      };
      gitlab = {
        enable = true;
        port = if cfg.expose-nginx then 443 else cfg.port;
        https = cfg.expose-nginx;
        host =
          if config.link.domain == "" then config.networking.hostName else "gitlab.${config.link.domain}";
        # host = "sn";
        statePath = cfg.storage;
        sidekiq.concurrency = 4;
        puma = {
          threadsMax = 1;
          workers = 1;
        };
        pages.settings.pages-domain =
          if config.link.domain == "" then "pages.${config.link.domain}" else config.networking.hostName;
        databaseCreateLocally = true;
        databasePasswordFile = config.sops.secrets."gitlab/dbPass".path;
        initialRootPasswordFile = config.sops.secrets."gitlab/initialRoot".path;
        extraEnv={SIDEKIQ_LOG_LEVEL = "WARN";};
        extraConfig = {
          gitlab = {
            trusted_proxies = [
              "127.0.0.1"
              "::1"
              "100.87.16.37"
            ];
          };
        };
        secrets = {
          activeRecordSaltFile = config.sops.secrets."gitlab/activeRecordSalt".path;
          activeRecordPrimaryKeyFile = config.sops.secrets."gitlab/activeRecordPrimary".path;
          activeRecordDeterministicKeyFile = config.sops.secrets."gitlab/activeRecordDeterministic".path;
          secretFile = config.sops.secrets."gitlab/secret".path;
          otpFile = config.sops.secrets."gitlab/otp".path;
          dbFile = config.sops.secrets."gitlab/db".path;
          jwsFile = config.sops.secrets."gitlab/jws".path;
          # jwsFile = pkgs.runCommand "oidcKeyBase" { } "${pkgs.openssl}/bin/openssl genrsa 2048 > $out";
        };
      };
    };
    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
    virtualisation.podman.enable = true;
    services.gitlab-runner = {
      enable = false;
      services = {
        # runner for building in docker via host's nix-daemon
        # nix store will be readable in runner, might be insecure
        nix = {
          dockerImage = "alpine";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          dockerDisableCache = true;
          preBuildScript = pkgs.writeScript "setup-container" ''
            mkdir -p -m 0755 /nix/var/log/nix/drvs
            mkdir -p -m 0755 /nix/var/nix/gcroots
            mkdir -p -m 0755 /nix/var/nix/profiles
            mkdir -p -m 0755 /nix/var/nix/temproots
            mkdir -p -m 0755 /nix/var/nix/userpool
            mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
            mkdir -p -m 1777 /nix/var/nix/profiles/per-user
            mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
            mkdir -p -m 0700 "$HOME/.nix-defexpr"
            . ${pkgs.nix}/etc/profile.d/nix.sh
            ${pkgs.nix}/bin/nix-env -i ${
              concatStringsSep " " (
                with pkgs;
                [
                  nix
                  cacert
                  git
                  openssh
                ]
              )
            }
            ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
            ${pkgs.nix}/bin/nix-channel --update nixpkgs
          '';
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
            NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
          };
          authenticationTokenConfigFile = config.sops.secrets."gitlab/runner-nix".path;
          dockerExtraHosts = [ "${config.networking.hostName}:127.0.0.1" ];
        };
        # runner for building docker images
        docker-images = {
          # File should contain at least these two variables:
          # `CI_SERVER_URL`
          # `CI_SERVER_TOKEN`
          dockerExtraHosts = [ "${config.networking.hostName}:127.0.0.1" ];
          authenticationTokenConfigFile = config.sops.secrets."gitlab/runner-default".path;

          dockerImage = "debian:stable";
          # dockerVolumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
        };
        # docker-protected = {
        #   # File should contain at least these two variables:
        #   # `CI_SERVER_URL`
        #   # `CI_SERVER_TOKEN`
        #   authenticationTokenConfigFile = config.sops.secrets."gitlab/runner-protected".path;

        #   dockerImage = "docker:stable";
        #   dockerVolumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
        #   tagList = [ "protected" ];
        # };
        # runner for executing stuff on host system (very insecure!)
        # make sure to add required packages (including git!)
        # to `environment.systemPackages`
        # shell = {
        #   # File should contain at least these two variables:
        #   # `CI_SERVER_URL`
        #   # `CI_SERVER_TOKEN`
        #   authenticationTokenConfigFile =
        #     "/run/secrets/gitlab-runner-shell-token-env";

        #   executor = "shell";
        #   tagList = [ "shell" ];
        # };
        # runner for everything else
        # default = {
        #   # File should contain at least these two variables:
        #   # `CI_SERVER_URL`
        #   # `CI_SERVER_TOKEN`
        #   authenticationTokenConfigFile =config.sops.secrets."gitlab/runner-default".path;
        #   dockerImage = "debian:stable";
        # };
      };
    };
    # services.gitlab-runner = {
    #   enable = true;
    #   settings = { listen_address = "127.0.0.1:443"; };
    #   services = {
    #     # runner for building in docker via host's nix-daemon
    #     # nix store will be readable in runner, might be insecure
    #     nix = {
    #       cloneUrl = "https://gitlab.${config.link.domain}";
    #       # File should contain at least these two variables:
    #       # - `CI_SERVER_URL`
    #       # - `REGISTRATION_TOKEN`
    #       #
    #       # NOTE: Support for runner registration tokens will be removed in GitLab 18.0.
    #       # Please migrate to runner authentication tokens soon. For reference, the example
    #       # runners below this one are configured with authentication tokens instead.
    #       authenticationTokenConfigFile =
    #         config.sops.secrets."gitlab/runner-nix".path;
    #       dockerImage = "alpine";
    #       dockerVolumes = [
    #         "/nix/store:/nix/store:ro"
    #         "/nix/var/nix/db:/nix/var/nix/db:ro"
    #         "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
    #       ];
    #       dockerDisableCache = true;
    #       preBuildScript = pkgs.writeScript "setup-container" ''
    #         mkdir -p -m 0755 /nix/var/log/nix/drvs
    #         mkdir -p -m 0755 /nix/var/nix/gcroots
    #         mkdir -p -m 0755 /nix/var/nix/profiles
    #         mkdir -p -m 0755 /nix/var/nix/temproots
    #         mkdir -p -m 0755 /nix/var/nix/userpool
    #         mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
    #         mkdir -p -m 1777 /nix/var/nix/profiles/per-user
    #         mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
    #         mkdir -p -m 0700 "$HOME/.nix-defexpr"

    #         . ${pkgs.nix}/etc/profile.d/nix.sh

    #         ${pkgs.nix}/bin/nix-env -i ${
    #           concatStringsSep " " (with pkgs; [ nix cacert git openssh ])
    #         }

    #         ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
    #         ${pkgs.nix}/bin/nix-channel --update nixpkgs
    #       '';
    #       environmentVariables = {
    #         ENV = "/etc/profile";
    #         USER = "root";
    #         NIX_REMOTE = "daemon";
    #         PATH =
    #           "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
    #         NIX_SSL_CERT_FILE =
    #           "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
    #       };
    #     };
    #     # runner for building docker images
    #     docker-images = {
    #       cloneUrl = "https://gitlab.${config.link.domain}";
    #       # File should contain at least these two variables:
    #       # `CI_SERVER_URL`
    #       # `CI_SERVER_TOKEN`
    #       authenticationTokenConfigFile =
    #         config.sops.secrets."gitlab/runner-default".path;
    #       dockerImage = "docker:stable";
    #       dockerVolumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    #     };
    #     protected = {
    #       cloneUrl = "https://gitlab.${config.link.domain}";
    #       # File should contain at least these two variables:
    #       # `CI_SERVER_URL`
    #       # `CI_SERVER_TOKEN`
    #       authenticationTokenConfigFile =
    #         config.sops.secrets."gitlab/runner-protected".path;
    #       dockerImage = "docker:stable";
    #       dockerVolumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    #     };
    #   };
    # };
    # networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
    #   mkIf cfg.expose-port
    #     [ cfg.port ];
    networking.firewall.interfaces."docker0".allowedTCPPorts = [ cfg.port ];
    systemd.services.gitlab-backup.environment.BACKUP = "dump";
  };
}
