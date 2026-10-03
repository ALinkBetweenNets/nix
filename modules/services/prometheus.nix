{
  config,
  system-config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.link.services.prometheus;
in
{
  options.link.services.prometheus = {
    enable = mkEnableOption "activate prometheus";
    expose-port = mkOption {
      type = types.bool;
      default = config.link.service-ports-expose;
      description = "directly expose the port of the application";
    };
    port = mkOption {
      type = types.int;
      default = 9005;
      description = "port to run the application on";
    };
  };
  config = mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        server.http_listen_port = 3162;
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
          # max_transfer_retries = 0;
        };

        schema_config = {
          configs = [
            {
              from = "2022-06-06";
              store = "boltdb-shipper";
              object_store = "filesystem";
              schema = "v11";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";
            cache_ttl = "24h";
            # shared_store = "filesystem";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          allow_structured_metadata = false;
        };

        # chunk_store_config = {
        #   max_look_back_period = "0s";
        # };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          # shared_store = "filesystem";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };
    # Promtail reached end of life; use Alloy to collect the journal and push it
    # to the local Loki instance instead.
    services.alloy = {
      enable = true;
    };
    environment.etc."alloy/config.alloy".text = ''
      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"
        }
      }

      loki.relabel "journal" {
        forward_to = [loki.write.local.receiver]

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.source.journal "journal" {
        max_age = "12h"
        labels = {
          job  = "systemd-journal",
          host = "pihole",
        }
        forward_to = [loki.relabel.journal.receiver]
      }
    '';
    services.prometheus = {
      enable = true;
      port = cfg.port;
      scrapeConfigs = [
        {
          job_name = "nodes";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              ];
            }
          ];
        }
        # {
        #   job_name = "blackboxhttp2xx";
        #   scheme = "http";
        #   metrics_path = "/";
        #   params = {
        #     module = [ "https_2xx" ];
        #   };
        #   static_configs = [
        #     {
        #       targets = [
        #         "gitlab.${config.link.domain}"
        #         "nextcloud.${config.link.domain}"
        #         "immich.${config.link.domain}"
        #         "100.108.233.76:3001"
        #       ];
        #       labels = {
        #         connectivity = "external";
        #       };
        #     }
        #   ];
        # }
        {
          job_name = "gitlab";
          scheme = "http";
          metrics_path = "/metrics";
          # params = {
          #   module = [ "https_2xx" ];
          # };
          static_configs = [
            {
              targets = [
                "localhost:80"
              ];
              # labels = {
              #   connectivity = "external";
              # };
            }
          ];
        }
        {
          job_name = "immich";
          scheme = "http";
          metrics_path = "/metrics";
          # params = {
          #   module = [ "https_2xx" ];
          # };
          static_configs = [
            {
              targets = [
                "localhost:8082"
                "localhost:8081"
              ];
              # labels = {
              #   connectivity = "external";
              # };
            }
          ];
        }

        # {
        #   job_name = "blackbox-restic";
        #   scheme = "http";
        #   metrics_path = "/probe";
        #   params = {
        #     module = [ "https_401" ];
        #   };
        #   static_configs = [
        #     {
        #       targets = [
        #         "restic.${config.link.domain}"
        #       ];
        #       labels = {
        #         connectivity = "external";
        #       };
        #     }
        #   ];
        # }
        # {
        #   job_name = "scraper";
        #   static_configs = [
        #     {
        #       targets = [
        #         "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
        #         "127.0.0.1:${toString config.services.prometheus.exporters.ping.port}"
        #         "127.0.0.1:${toString config.services.prometheus.exporters.domain.port}"
        #         # "127.0.0.1:${
        #         #   toString config.services.prometheus.exporters.postgres.port
        #         # }"
        #         "127.0.0.1:${toString config.services.prometheus.exporters.redis.port}"
        #         # "127.0.0.1:${
        #         # toString config.services.prometheus.exporters.restic.port
        #         # }"
        #         "127.0.0.1:${toString config.services.prometheus.exporters.statsd.port}"
        #         "127.0.0.1:${toString config.services.prometheus.exporters.smokeping.port}"
        #         # "127.0.0.1:${
        #         #   toString config.services.prometheus.exporters.blackbox.port
        #         # }"
        #
        #       ];
        #     }
        #   ];
        # }
      ];

      exporters = {

        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            # "cpu"
            # "diskstats"
            # "filesystem"
            # "loadavg"
            # "meminfo"
            # "netdev"
            # "stat"
            # "time"
          ];
        };
        # ping = {
        #   enable = true;
        #   settings = {
        #     targets = [ "1.0.0.1" ];
        #     interval = "20s";
        #     timeout = "5s";
        #     history-size = "120";
        #     payload-size = "64";
        #   };
        # };
        # domain.enable = true;
        # postgres.enable = true;
        postgres.runAsLocalSuperUser = true;
        # redis.enable = true;
        # restic.enable = true;
        # statsd.enable = true;
        # smokeping = {
        #   enable = true;
        #   hosts = [
        #     "1.0.0.1"
        #     "alinkbetweennets.de"
        #     "100.98.48.88"
        #     "mullvad.net"
        #     "9.9.9.9"
        #     "telekom.de"
        #     "100.87.16.37"
        #     "100.108.198.22"
        #   ];
        #   pingInterval = "1s";
        #   listenAddress = "127.0.0.1";
        # };
        blackbox = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9115;
          configFile = pkgs.writeText "blackboxconfig.yml" (
            lib.generators.toYAML { } {
              modules = {
                https_2xx = {
                  prober = "http";
                  timeout = "20s";
                  http = {
                    valid_http_versions = [
                      "HTTP/1.1"
                      "HTTP/2.0"
                    ];
                    valid_status_codes = [ ]; # Defaults to 2xx
                    method = "GET";
                    follow_redirects = true;
                    fail_if_ssl = false;
                    fail_if_not_ssl = true;
                    tls_config = {
                      insecure_skip_verify = false;
                    };
                    preferred_ip_protocol = "ip4"; # defaults to "ip6"
                    ip_protocol_fallback = true; # # no fallback to "ip6"
                  };
                };
                # https_401 = {
                #   prober = "http";
                #   timeout = "20s";
                #   http = {
                #     valid_http_versions = [
                #       "HTTP/1.1"
                #       "HTTP/2.0"
                #     ];
                #     valid_status_codes = [401 ]; # Defaults to 2xx
                #     method = "GET";
                #     follow_redirects = true;
                #     fail_if_ssl = false;
                #     fail_if_not_ssl = true;
                #     tls_config = {
                #       insecure_skip_verify = false;
                #     };
                #     preferred_ip_protocol = "ip4"; # defaults to "ip6"
                #     ip_protocol_fallback = true; # # no fallback to "ip6"
                #   };
                # };

                # tls_connect = {
                #   prober = "tcp";
                #   timeout = "5s";
                #   tcp = {
                #     tls = true;
                #   };
                # };
                # modules:
                #   http_2xx:
                #     prober: http
                #     timeout: 20s
                # http:
                # httip_post_2xx:
                #   prober: http
                #   timeout: 5s
                #   http:
                #     method: POST
                #     body_size_limit: 1MB
                # tcp_connect:
                #   prober: tcp
                #   timeout: 5s
                # pop3s_banner:
                #   prober: tcp
                #   tcp:
                #     query_response:
                #     - expect: "^+OK"
                #     tls: true
                #     tls_config:
                #       insecure_skip_verify: false
                # ssh_banner:
                #   prober: tcp
                #   timeout: 5s
                #   tcp:
                #     query_response:
                #     - expect: "^SSH-2.0-"
                # smtp_starttls:
                #   prober: tcp
                #   timeout: 5s
                #   tcp:
                #     query_response:
                #     - expect: "^220 "
                #     - send: "EHLO prober\r"
                #     - expect: "^250-STARTTLS"
                #     - send: "STARTTLS\r"
                #     - expect: "^220"
                #     - starttls: true
                #     - send: "EHLO prober\r"
                #     - expect: "^250-AUTH"
                #     - send: "QUIT\r"
                # irc_banner:
                #   prober: tcp
                #   timeout: 5s
                #   tcp:
                #     query_response:
                #     - send: "NICK prober"
                #     - send: "USER prober prober prober :prober"
                #     - expect: "PING :([^ ]+)"
                #       send: "PONG ${1}"
                #     - expect: "^:[^ ]+ 001"
                # icmp_test:
                #   prober: icmp
                #   timeout: 5s
                #   icmp:
                #     preferred_ip_protocol: ip4
                # dns_test:
                #   prober: dns
                #   timeout: 5s
                #   dns:
                #     query_name: example.com
                #     preferred_ip_protocol: ip4
                #     ip_protocol_fallback: false
                #     validate_answer_rrs:
                #       fail_if_matches_regexp: [test]
                # http_header_match_origin:
                #   prober: http
                #   timeout: 5s
                #   http:
                #     method: GET
                #     headers:
                #       Origin: example.com
                #     fail_if_header_not_matches:
                #     - header: Access-Control-Allow-Origin
                #       regexp: '(\*|example\.com)'
                #       allow_missing: false
                # '';
              };
            }
          );
        };

        # zfs = {
        #   enable = true;
        #   listenAddress = "0.0.0.0";
        # };
        # nextcloud={
        #   enable=true;
        #   username="l";
        #   user="l";
        #   port="443";
        # };
      };
      # scrapeConfigs = [{
      #   job_name = "zfs";
      #   static_configs =
      #     [{ targets = [ "127.0.0.1:${toString cfg.port}" ]; }];
      # }];
    };

    networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
      mkIf cfg.expose-port
        [ cfg.port ];
  };
}
