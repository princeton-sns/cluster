{ config, pkgs, lib, ... }:

with lib;

let
  dataDir = "/var/lib/matrix-appservice-slack";
  registrationFile = "${dataDir}/registration.yaml";
  matrix_host = "https://adam.cs.princeton.edu";
  settings = {
    homeserver = {
      server_name = "princeton.systems";
      url = matrix_host;
      appservice_port = 5858;
      appservice_host = "127.0.0.1";
    };
    username_prefix = "slack_";
    db = {
      engine = "postgres";
      connectionString = "postgres:///?host=/var/run/postgresql";
    };
    matrix_admin_room = "!oXEKSzAdAuxiZzDjCK:princeton.systems";
    rtm = {
      enable = true;
      log_level = "silent";
    };
  };
  configFile = pkgs.writeText "matrix-appservice-slack-config.json" (builtins.toJSON settings);
in {
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "slackbridge" ];
    ensureUsers = [{
      name = "slackbridge";
      ensurePermissions = { "DATABASE slackbridge" = "ALL PRIVILEGES"; };
    }];
  };
  
  users.users.slackbridge = {
    description = "matrix-appservice-slack";
    home = dataDir;
    homeMode = "770";
    group = "matrix-synapse";
    isSystemUser = true;
    createHome = true;
  };
  
  systemd.services.matrix-appservice-slack = {
    description = "matrix-appservice-slack";
    wants = [ "network.target" "postgresql.service" ] ;
    after = [ "network.target" "postgresql.service" ] ;
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      if [ ! -f '${registrationFile}' ]; then
          ${pkgs.matrix-appservice-slack}/bin/matrix-appservice-slack \
              -r \
              -u http://localhost:5858 \
              -c ${configFile} \
              -f ${registrationFile}
          fi
    '';
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ dataDir ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;

      PrivateTmp = true;
      User = "slackbridge";
      Group = "matrix-synapse";
      ExecStart = ''
        ${pkgs.matrix-appservice-slack}/bin/matrix-appservice-slack -c ${configFile} -f ${registrationFile}
      '';
      Restart = "on-failure";
    };
  };
  
  services.matrix-synapse.settings.app_service_config_files = [ registrationFile ];

} 
