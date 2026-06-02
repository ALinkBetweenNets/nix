{
config,
system-config,
pkgs,
lib,
...
}:
with lib;
let
  cfg = config.link.syncthing;
in
  {
  options.link.syncthing.enable = mkEnableOption "activate syncthing";
  config = mkIf cfg.enable {
    # systemd.tmpfiles.rules = [ "d /var/lib/syncthing 1700 l wheel -" ];
    networking.firewall = {
      allowedTCPPorts = [
        # 8384
        22000 # Syncthing
      ];
      allowedUDPPorts = [
        22000 # syncthing
        21027 # syncthing
      ];
    };
    environment.systemPackages = with pkgs; [ syncthing ];
    systemd.services.syncthing.environment = { GOMAXPROCS="1";};
    services.syncthing = {
      enable = true;
      user = "l";
      openDefaultPorts = true;
      dataDir = config.link.syncthingDir;
      settings = {
        setLowPriority = true;
        maxFolderConcurrency=1;
        globalAnnounceEnabled=false;
        relaysEnabled=false;
        extraOptions.gui = {
          theme = "black";
          user = "l";
        };
        # overrides any devices added or deleted through the WebUI
        overrideDevices = true;
        # overrides any folders added or deleted through the WebUI
        overrideFolders = true;
        devices = {
          "dn".id = "2UZCLBR-LR5DMFA-HWXNELR-3GF6BVU-RZEBCWZ-P72JF4N-ZV7H6MF-SEQX4QK";
          "xn".id = "Z5CMPPX-PFIAWAO-NFTUO3B-E4MKXAS-EKD3JKU-7E6BYFG-SH34CRI-2W56QA2";
          "fn".id = "YPG6EYA-VRGS6CZ-5X6HXEM-ABGDCRY-7EIVCWL-2K4U4XQ-KA2W6H6-JYY4PAQ";
          "s22".id = "V446NPI-YZNXTZL-5LFFQFV-GW7DXHV-IMAX7VX-B27RYFO-FZFSEYG-TMSTTAR";
          "in".id = "IYOMGJ7-NZADKG2-L2PMGIH-VSTMTJ4-KLA7VF4-3CUONC2-BQMMWTW-I6KHDAY";
          "sn".id = "SSSFCB5-W4CIMVK-L33WJ4F-VBH4FZW-SZIRMMN-IGHQ7MA-BBTFKYM-V2NSDQS";
          "nn".id = "SJCV4A4-SCRP5NW-FBNEQIR-HVZBPYG-ASSG6A7-KR4KUXY-5OWXYOS-CXMBKQE";
          "npn".id = "PNVPZKG-I4RHS42-CEO4OMC-7ILR3TP-DK463Q4-32FAZ3P-WVZUA5T-KDRHPQA";
          "hn".id = "YU4MCML-QWAYIDE-FSHCDWA-C2FGKTG-ERS6I36-SMCFI2J-RKLVOPN-PS3IFQD";
          "pppn".id = "JCOKRQ5-67ARNA3-VOO4EOZ-5GUPCU6-63FSAID-EI4MVHH-T5ORT3Y-OFAGAAY";
          "p4n".id = "D64D4HR-7GZLZDK-UZKAFD5-YBJAURJ-Q2HXQB2-LNFYZNU-HNOIYFY-JUMR5A5";
          "pg".id = "PT4XFJ6-PLNWZ2E-PDPAPV7-5ECSKA2-3EEHMPJ-L6JWB46-TDO5HZJ-LVMSTA7";
        };
        folders = {
          "transfer" = {
            path = lib.mkDefault "${config.link.syncthingDir}/transfer";
            devices = [
              "nn"
              "sn"
            ];
          };
          "v" = {
            path = lib.mkDefault "${config.link.syncthingDir}/v";
            devices = [
              "dn"
              "fn"
              "hn"
              "in"
              "s22"
              "nn"
              "sn"
              "npn"
              "xn"
              # "pg"
            ];
          };
          "camera" = {
            path = lib.mkDefault "${config.link.syncthingDir}/camera";
            devices = [
              "s22"
              "sn"
              "nn"
              "npn"
              # "pg"
            ];
            versioning = {
              type = "trashcan";
              params.cleanoutDays = "1000";
            };
          };
          "uni" = {
            path = lib.mkDefault "${config.link.syncthingDir}/uni";
            devices = [
              "dn"
              "hn"
              "fn"
              "in"
              "s22"
              "sn"
              "nn"
              "xn"
              "npn"
              # "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "3";
            };
          };
          "w" = {
            path = lib.mkDefault "${config.link.syncthingDir}/w";
            devices = [
              "dn"
              "fn"
              "hn"
              "sn"
              "nn"
              "xn"
              "npn"
              # "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "5";
            };
          };
          "github" = {
            path = lib.mkDefault "${config.link.syncthingDir}/github";
            devices = [
              "dn"
              "fn"
              "hn"
              "nn"
              "xn"
              "npn"
            ];
          };
          "mirror" = {
            path = lib.mkDefault "${config.link.syncthingDir}/.data-mirror";
            devices = [
              "fn"
              "xn"
              "nn"
              "sn"
              "p4n"
              "npn"
              # "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "3";
            };
          };
          "backups" = {
            path = lib.mkDefault "${config.link.syncthingDir}/backups";
            devices = [
              "sn"
              "p4n"
              "nn"
            ];
            versioning = {
              type = "simple";
              params.keep = "3";
            };
          };
          "archive" = {
            path = lib.mkDefault "${config.link.syncthingDir}/archive";
            devices = [
              "dn"
              "fn"
              "xn"
              "nn"
              "sn"
              "npn"
              # "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "3";
            };
          };
          "doc" = {
            path = lib.mkDefault "${config.link.syncthingDir}/doc";
            devices = [
              "dn"
              "fn"
              "hn"
              "in"
              "nn"
              "s22"
              "sn"
              "xn"
              "npn"
              # "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "5";
            };
          };
          "music" = {
            path = lib.mkDefault "${config.link.syncthingDir}/Music";
            devices = [
              "dn"
              "fn"
              "hn"
              "in"
              "s22"
              "nn"
              "sn"
              "xn"
              "npn"
              "pg"
            ];
            versioning = {
              type = "trashcan";
              params.cleanoutDays = "1000";
            };
          };
          "crypt" = {
            path = lib.mkDefault "${config.link.syncthingDir}/crypt";
            devices = [
              "dn"
              "fn"
              "hn"
              "nn"
              "in"
              "sn"
              "xn"
              "npn"
            ];
          };
          "sec" = {
            path = lib.mkDefault "${config.link.syncthingDir}/sec";
            devices = [
              "dn"
              "fn"
              "hn"
              "nn"
              "in"
              "sn"
              "xn"
              "pppn"
              "npn"
              "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
          # "obsidian" = {
          #   path = lib.mkDefault "${config.link.syncthingDir}/obsidian";
          #   devices = [ "fn" "sn" "xn" "s22" "pppn" ];
          #   versioning = {
          #     type = "simple";
          #     params.keep = "5";
          #   };
          # };
          "keys" = {
            path = lib.mkDefault "${config.link.syncthingDir}/.keys";
            devices = [
              "dn"
              "fn"
              "hn"
              "in"
              "sn"
              "xn"
              "npn"
              "nn"
              # "pg"
            ];
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };

        };
      };
    };
  };
}
