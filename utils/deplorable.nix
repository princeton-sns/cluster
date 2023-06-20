{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.deplorable;
  deplorablePkg = import (pkgs.fetchFromGitHub {
    owner = "alevy";
    repo = "deplorable";
    rev = "9f6dae912e26e1085ce83a9d8ae4378909a69a8";
    sha256 = "sha256-wk80fATOp6EB3Rcex4xM/kIDmR25dxMNnh4nUHXzxcI=";
  }) {};
  configFile = pkgs.writeText "config.yaml" (builtins.toJSON cfg.config);
in {
  options = {
    services.deplorable = {
      enable = mkEnableOption "Deplorable";
      port = mkOption {
        type = types.port;
        default = 1337;
        example = 1337;
        description = ''
          TCP port to listen for incoming connections.
        '';
      };
      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        example = "0.0.0.0";
        description = ''
          Address to listen for incoming connections.
        '';
      };
      openFirewall = mkOption {
        type = types.bool;
        default = false;
      };
      config = mkOption {
        type = types.attrs;
        default = {
          repos = {};
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ deplorablePkg ];
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.deplorable = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Deplorable service";
      path = [ pkgs.nix pkgs.gnutar pkgs.gzip ];
      environment = {
        XDG_CACHE_HOME = "/var/cache/deplorable";
        NIX_PATH = concatStringsSep ":" [
          "/nix/var/nix/profiles/per-user/root/channels/nixos"
          "nixos-config=/etc/nixos/configuration.nix"
          "/nix/var/nix/profiles/per-user/root/channels"
        ];
      };
      serviceConfig = {
        User = "deplorable";
        ExecStart = "${deplorablePkg}/bin/deplorable -l ${cfg.listenAddress}:${toString cfg.port} -c ${configFile}";
        Restart = "on-failure";
        PrivateTmp = true;
        StateDirectory = [ "deplorable" ];
        WorkingDirectory = [ "/var/lib/deplorable"];
        CacheDirectory = [ "deplorable" ];
      };
    };

    users.users = {
      deplorable = {
        isSystemUser = true;
        group = "deplorable";
      };
    };

    users.groups = {
      deplorable = {};
    };
  };
}
