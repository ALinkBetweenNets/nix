{
  config,
  system-config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.link.nginx;
in
{
  options.link.nginx.enable = mkEnableOption "activate nginx";
  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [
      80
      443
    ];
    networking.firewall.allowedTCPPorts = [
      # 25
      80
      # 143
      443
      # 993
      # 111
      # 2049
      # 4000
      # 4001
      # 4002
    ];
    # networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ]; # nfs
    services.nginx = {
      # additionalModules = with pkgs.nginxModules; [ env ];
      enable = true;
      # recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      experimentalZstdSettings = true;
      # recommendedTlsSettings = true;
      logError = "stderr debug";
      enableQuicBPF = true;
      package = pkgs.nginxMainline.override {
        #openssl = pkgs.libressl;
        openssl = pkgs.openssl_oqs;
        modules = with pkgs.nginxModules; [ geoip2 ]; # echo
        buildInputs = oldAttrs.buildInputs ++ [ pkgs.libmaxminddb ];
      };
      clientMaxBodySize = "6000m";
      sslProtocols = "TLSv1.2 TLSv1.3";
      # sslCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:@SECLEVEL=2"; # Mozilla recommendation
      sslCiphers = ''
        ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384
      '';
      commonHttpConfig = ''
        ssl_conf_command Ciphersuites TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;
        # ssl_ciphers = "AES256+EECDH:AES256+EDH:!aNULL@SECLEVEL=2";
        ssl_ecdh_curve X25519MLKEM768:X25519:secp384r1:secp256r1;
        # ssl_protocols TLSv1.2 TLSv1.3;
        # ssl_ciphers HIGH:!aNULL:!MD5:@SECLEVEL=2;
        # ssl_conf_command Options KTLS; # not supported on nc
        # ssl_conf_command Groups "X25519MLKEM768:X25519:P-256:P-384"
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m; # 40000 sessions
        # cache_max_size 1g;
        # cache_valid 200 30m;
        # Breaks forward secrecy: https://github.com/mozilla/server-side-tls/issues/135
        ssl_session_tickets off;
        # We don't enable insecure ciphers by default, so this allows
        # clients to pick the most performant, per https://github.com/mozilla/server-side-tls/issues/260
        ssl_prefer_server_ciphers off;
        # ssl_prefer_server_ciphers on; # disabled as only secure ciphers enabled. Clients may choose the most performant cipher for them from our whitelist
        log_format forensic escape=json
'{'
'"time":"$time_iso8601",'
'"msec":"$msec",'
'"connection":"$connection",'
'"connection_requests":"$connection_requests",'
'"pid":"$pid",'

'"remote_addr":"$remote_addr",'
'"realip_remote_addr":"$realip_remote_addr",'
'"proxy_protocol_addr":"$proxy_protocol_addr",'
'"xff":"$http_x_forwarded_for",'

'"request":"$request",'
'"request_method":"$request_method",'
'"scheme":"$scheme",'
'"host":"$host",'
'"server_name":"$server_name",'
'"server_addr":"$server_addr",'
'"server_port":"$server_port",'
'"uri":"$uri",'
'"request_uri":"$request_uri",'
'"args":"$args",'
'"query_string":"$query_string",'

'"status":"$status",'
'"body_bytes_sent":"$body_bytes_sent",'
'"bytes_sent":"$bytes_sent",'
'"request_length":"$request_length",'

'"request_body":"$request_body",'

'"http_user_agent":"$http_user_agent",'
'"http_referer":"$http_referer",'
'"http_cookie":"$http_cookie",'
'"content_type":"$content_type",'
'"http_content_type":"$http_content_type",'
'"http_content_length":"$http_content_length",'
'"http_authorization":"$http_authorization",'

'"ssl_protocol":"$ssl_protocol",'
'"ssl_cipher":"$ssl_cipher",'
'"https":"$https",'

'"upstream_addr":"$upstream_addr",'
'"upstream_status":"$upstream_status",'
'"upstream_response_time":"$upstream_response_time",'
'"upstream_connect_time":"$upstream_connect_time",'
'"upstream_header_time":"$upstream_header_time",'

'"request_completion":"$request_completion",'
'"pipe":"$pipe"'
'}';
log_format detailed
'$time_iso8601 '
'$remote_addr '

'host="$host" '
'vhost="$server_name" '
'dst="$server_addr:$server_port" '

'req="$request" '
'method="$request_method" '
'uri="$request_uri" '
'args="$args" '

'proto="$server_protocol" '
'status=$status '
'time=$request_time '

'ssl="$ssl_protocol" '
'cipher="$ssl_cipher" '
'up_status="$upstream_status" '
'up_time="$upstream_response_time" '

'ua="$http_user_agent" '
'xff="$http_x_forwarded_for" '
'body:"$request_body" ';
        access_log /var/log/nginx/detailed.log detailed;
       # log_format detailed '[$time_local] $remote_addr $remote_user ($http_x_forwarded_for)'
       #   '"$request" $http_referer $request_uri $status $body_bytes_sent '
       #   ' "$http_user_agent"'
       #   '-- "$request_body"';
        # log_format body '[$time_local] $remote_addr $remote_user'
        #   '"$request" $status $body_bytes_sent '
        #   '"$http_referer" "$http_user_agent"'
        #   ' -- "$request_body"';
        # Adding this header to HTTP requests is discouraged
        index index.php index.html /index.php$request_uri;
        server_names_hash_bucket_size 128;
        proxy_headers_hash_max_size 1024;
        proxy_headers_hash_bucket_size 256;
        # keepalive_max_robots 100;
        # keepalive_timeout 65;
        # Add HSTS header with preloading to HTTPS requests.
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        # proxy_hide_header Strict-Transport-Security;
        # ssl_stapling on; # discontinued by lets encrypt in favor of certificate revocation list
        # ssl_stapling_verify on;
        resolver 1.1.1.1 9.9.9.9 8.8.8.8 valid=300s;
        resolver_timeout 15s;
        # proxy_hide_header Content-Security-Policy; # maybe remove this
        # add_header Content-Security-Policy "frame-ancestors 'self' resource: blob: https://*.${config.link.domain} ws://*.${config.link.domain} ; object-src 'none'; default-src 'self' 'unsafe-inline' 'unsafe-eval' resource: data: blob: https://*.${config.link.domain} ws://*.${config.link.domain} https://tiles.immich.cloud https://static.immich.cloud https://api-l.cofractal.com https://maputnik.github.io https://fonts.openmaptiles.org https://fonts.googleapis.com ; script-src 'self' 'unsafe-eval' resource: blob: https://*.${config.link.domain} ws://*.${config.link.domain} 'sha256-tq5fHKUNWCWMHbqZJgps3MZdMB//nQ7ZNRkFNo18098=' 'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-Y1z0SyVx5S7ywM8HEuxVVkmBpqUjj6qZLBNBVk8E6h8=' 'sha256-UOoHSE7EadmP3+ngOCGeSjlMRRUHEmkJYHp72XcJwMA=' 'sha256-h5wSYKWbmHcoYTdkHNNguMswVNCphpvwW+uxooXhF/Y='; script-src-elem 'self' resource: blob: https://*.${config.link.domain} ws://*.${config.link.domain} 'sha256-tq5fHKUNWCWMHbqZJgps3MZdMB//nQ7ZNRkFNo18098=' 'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-Y1z0SyVx5S7ywM8HEuxVVkmBpqUjj6qZLBNBVk8E6h8=' 'sha256-UOoHSE7EadmP3+ngOCGeSjlMRRUHEmkJYHp72XcJwMA=' 'sha256-h5wSYKWbmHcoYTdkHNNguMswVNCphpvwW+uxooXhF/Y=' 'sha256-Y1z0SyVx5S7ywM8HEuxVVkmBpqUjj6qZLBNBVk8E6h8=' 'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-OGjU0xQxuhdJDf8iMcgZXmRJZD2QZBQJRLwrFlOBLkI=' 'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-OGjU0xQxuhdJDf8iMcgZXmRJZD2QZBQJRLwrFlOBLkI=' 'sha256-R5+O+GguAMEaEziO1n5XU7JdxbmNH9PrD0455tGIo+Y=' 'sha256-R/9llE0s4++pxJWFqpVdB+eQJk2ANaxrUkOoEgbf4BE=' 'sha256-+ac8khtNoT0aNZRgSgtufqMcKat1zoMcy2QKOy1king=' 'sha256-OEAthcFABIfn7TlCbTV6bGAv1qO5kVS02Tbru9uBM7E=' 'sha256-550mecyv+58pd1gBLH1QBIOUYSFa6dRGnPr5EQydW1Y=' 'sha256-XqyszejV2KjHp1R/rjEZrlZr+jaJpoSSF34CliTkwsA=' 'sha256-EzOdKxNif8wH7zIpBWq8C8s7ReXFFUgKIeh3S8mbzmg=' 'sha256-fWlVIwe2LsO09S7H48jPEdZpXqvWNASN9MJtP9UqorQ=' 'sha256-Ern5sY1mky3O39ew4yIsmsreULYL0UfzdgXhDHHkTPk=' 'sha256-Hf1/Ua2DBxqfO0jS+TExfy0QkxfQ/RCA0ALgPpc3oW4=' 'sha256-yei5Fza+Eyx4G0smvN0xBqEesIKumz6RSyGsU3FJowI=' 'sha256-WZgnIkFlgCl0JmazO0TxbWFV5KE/0m575qqqeOJXNiY='; script-src-attr 'sha256-oNF8YtSSei2EPkLN6iJsay+qCcAZgU5mVplFnaA5kfg=' 'sha256-DUmqk1AXx/CqEzEDi3kN1MUUIkfKPqpR8Ghp26MQHhA=' 'sha256-J7kWtYM4KIyNHU6eNQqga3n096TklczXivfzRupFyaE=' 'unsafe-hashes' ; font-src https://fonts.openmaptiles.org https://fonts.googleapis.com https://fonts.gstatic.com 'self' 'unsafe-inline' 'unsafe-eval' data: blob: ; img-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https://secure.gravatar.com https://videos.owncast.online https://www.gravatar.com https://logo.clearbit.com http://*.${config.link.domain} https://*.${config.link.domain} ws://*.${config.link.domain} ; frame-src 'self' 'unsafe-inline' https://*.${config.link.domain} ws://*.${config.link.domain} https://www.youtube.com https://youtube.com https://www.youtu.be https://gpu.alinkbetweennets.de ; media-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https://assets.owncast.tv https://videos.owncast.online https://www.gravatar.com https://logo.clearbit.com https://*.${config.link.domain} ws://*.${config.link.domain} ; base-uri 'self' *.${config.link.domain} ${config.link.domain};" always;
        # for inside csp: report-uri http://v2202312204123249185.ultrasrv.de:4000; report-to default
        # add_header Report-To '{"max_age":31536000,"endpoints":[{"url":"https://collect.alinkbetweennets.de"}]}';
        # no-referrer
        add_header Referrer-Policy strict-origin;
        # proxy_hide_header X-Frame-Options;
        add_header X-Frame-Options sameorigin;
        # add_header X-Frame-Options DENY;
        # Prevent injection of code in other mime types (XSS Attacks)
        # proxy_hide_header X-Content-Type-Options;
        add_header X-Content-Type-Options nosniff always;
        # This might create errors - doc
        # Yep it destroyed the immich login - me
        #proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header Host $host;
        proxy_set_header origin $http_origin;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        add_header X-XSRF-TOKEN $http_x_xsrf_token;
        # proxy_connect_timeout 300;
        # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
        #proxy_http_version 1.1;
        add_header Connection "";
        # chunked_transfer_encoding off;
        # To allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        # Set to a value such as 1000m; to restrict file size to a specific value
        # client_max_body_size 2048M;
        # To disable buffering
        proxy_buffering off;
        # add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag "noindex, nofollow";
        # add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        # add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
        fastcgi_buffers 64 4K;
        fastcgi_hide_header X-Powered-By;
        # gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        # gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
      '';
    };
  };
}
