{ config, system-config, pkgs, lib, ... }:
with lib;
let
  cfg = config.link.services.wallabag;
  dataDir = "${config.link.storage}/wallabag";
  wallabag = pkgs.wallabag;
  phpPackage = pkgs.php.withExtensions ({ enabled, all }:
    enabled ++ (with all; [
      ctype
      curl
      dom
      gd
      iconv
      imagick
      intl
      mbstring
      pdo
      pdo_pgsql
      simplexml
      tidy
      tokenizer
    ]));
  console =
    "WALLABAG_DATA=${dataDir} ${phpPackage}/bin/php ${wallabag}/bin/console --no-interaction --env=prod";
  domainName = 
    "https://wallabag.${config.link.domain}";
in {
  options.link.services.wallabag = {
    enable = mkEnableOption "activate wallabag";
    expose-port = mkOption {
      type = types.bool;
      default = config.link.service-ports-expose;
      description = "directly expose the port of the application";
    };
    nginx = mkOption {
      type = types.bool;
      default = config.link.nginx.enable;
      description =
        "expose the application to the internet with NGINX and ACME";
    };
    nginx-expose = mkOption {
      type = types.bool;
      default = config.link.nginx-expose;
      description = "expose the application to the internet";
    };
    port = mkOption {
      type = types.int;
      default = 6779;
      description = "port to run the application on";
    };
    registration = mkOption {
      type = types.bool;
      default = false;
      description = "allow public user registration";
    };
  };
  config = mkIf cfg.enable {
    users.users.wallabag = {
      isSystemUser = true;
      group = "wallabag";
    };
    users.groups.wallabag = { };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "wallabag" ];
      ensureUsers = [{
        name = "wallabag";
        ensureDBOwnership = true;
      }];
    };

    systemd.tmpfiles.rules = [ "d ${dataDir} 0750 wallabag wallabag - -" ];

    systemd.services.wallabag-install = {
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
      before = [ "phpfpm-wallabag.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ phpPackage pkgs.openssl ];
      serviceConfig = {
        Type = "oneshot";
        User = "wallabag";
        Group = "wallabag";
        RemainAfterExit = true;
      };
      # ponytail: single-user sync mode; add a redis import worker only if bulk imports get slow
      script = ''
        set -eu
        # Symfony resolves config relative to getProjectDir()=WALLABAG_DATA
        # (e.g. ../../src/Wallabag/...), so the whole project layout must live
        # here. Symlink the immutable parts from the store; keep app/var/data
        # writable.
        for d in ${wallabag}/*; do
          name=$(basename "$d")
          case "$name" in
            app|var|data) ;;
            *) ln -sfn "$d" ${dataDir}/"$name" ;;
          esac
        done
        rm -rf ${dataDir}/app
        cp -r --no-preserve=mode ${wallabag}/app ${dataDir}/app
        mkdir -p ${dataDir}/var/cache ${dataDir}/var/logs ${dataDir}/var/sessions ${dataDir}/data
        rm -rf ${dataDir}/var/cache/*
        [ -f ${dataDir}/secret.txt ] || (umask 077; openssl rand -hex 32 > ${dataDir}/secret.txt)
        SECRET=$(cat ${dataDir}/secret.txt)
        cat > ${dataDir}/app/config/parameters.yml <<EOF
        parameters:
            database_driver: pdo_pgsql
            database_host: /run/postgresql
            database_port: ~
            database_name: wallabag
            database_user: wallabag
            database_password: ~
            database_path: null
            database_table_prefix: wallabag_
            database_socket: null
            database_charset: utf8
            domain_name: ${domainName}
            server_name: "wallabag"
            mailer_dsn: smtp://127.0.0.1
            locale: en
            secret: $SECRET
            twofactor_sender: no-reply@${config.link.domain}
            fosuser_registration: ${boolToString cfg.registration}
            fosuser_confirmation: false
            fos_oauth_server_access_token_lifetime: 3600
            fos_oauth_server_refresh_token_lifetime: 1209600
            from_email: no-reply@${config.link.domain}
            rss_limit: 50
            redis_scheme: tcp
            redis_host: localhost
            redis_port: 6379
            redis_path: null
            redis_password: null
            rabbitmq_host: localhost
            rabbitmq_port: 5672
            rabbitmq_user: guest
            rabbitmq_password: guest
            rabbitmq_prefetch_count: 10
            sentry_dsn: ~
        EOF
        if [ ! -f ${dataDir}/.installed ]; then
          ${console} wallabag:install
          touch ${dataDir}/.installed
        else
          ${console} doctrine:migrations:migrate
        fi
        ${console} cache:clear
      '';
    };

    services.phpfpm.pools.wallabag = {
      inherit phpPackage;
      user = "wallabag";
      group = "wallabag";
      phpEnv.WALLABAG_DATA = dataDir;
      phpOptions = "memory_limit = 256M";
      settings = {
        "listen.owner" = "nginx";
        "listen.group" = "nginx";
        "pm" = "dynamic";
        "pm.max_children" = 15;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 3;
        "clear_env" = false;
        "catch_workers_output" = 1;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.wallabag = {
        serverName = "wallabag.${config.link.domain}";
        root = "${wallabag}/web";
        listen =  [{
          addr = "0.0.0.0";
          port = cfg.port;
        }];
        locations."/".tryFiles = "$uri /app.php$is_args$args";
        locations."= /app.php".extraConfig = ''
          fastcgi_pass unix:${config.services.phpfpm.pools.wallabag.socket};
          include ${config.services.nginx.package}/conf/fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param DOCUMENT_ROOT $document_root;
          internal;
        '';
        locations."~ \\.php$".extraConfig = "return 404;";
        # extraConfig = ''
        #   allow ${config.link.service-ip}/24;
        #   allow 127.0.0.1;
        #   deny all;
        # '';
      };
    };

    networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
      mkIf cfg.expose-port [ cfg.port ];
  };
}
