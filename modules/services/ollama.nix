{ config, pkgs, lib, ... }:
with lib;
let cfg = config.link.services.ollama;
in {
  options.link.services.ollama = {
    enable = mkEnableOption "activate ollama";
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
      default = 11434;
      description = "port to run the application on";
    };
  };
  config = mkIf cfg.enable {
    services = {
      ollama = {
        enable = true;
        port = cfg.port;
        host = if cfg.expose-port then "0.0.0.0" else "127.0.0.1";
        # loadModels = [ "gemma3:27b" "nomic-embed-text" ];
      };
      nextjs-ollama-llm-ui = {
        enable = true;
        port = 11435;
        ollamaUrl =
          if cfg.expose-port then
            "http://0.0.0.0:11435"
          else
            "127.0.0.1:11435";
      };
      # private-gpt = {
      #   enable = true;
      #   settings = {
      #     azopenai = { };
      #     data = { local_data_folder = "/var/lib/private-gpt"; };
      #     embedding = { mode = "ollama"; };
      #     llm = {
      #       mode = "ollama";
      #       tokenizer = "";
      #     };
      #     ollama = {
      #       api_base = "http://localhost:11434";
      #       embedding_api_base = "http://localhost:11434";
      #       embedding_model = "nomic-embed-text";
      #       keep_alive = "5m";
      #       llm_model = "llama3.1:405b";
      #       repeat_last_n = 64;
      #       repeat_penalty = 1.2;
      #       request_timeout = 120;
      #       tfs_z = 1;
      #       top_k = 40;
      #       top_p = 0.9;
      #     };
      #     openai = { };
      #     qdrant = { path = "/var/lib/private-gpt/vectorstore/qdrant"; };
      #     vectorstore = { database = "qdrant"; };
      #   };
      # };
      nginx.virtualHosts."ollama.${config.link.domain}" = mkIf cfg.nginx {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}/";
        };
      };
    };
    networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
      mkIf cfg.expose-port [ cfg.port ];
  };
}
