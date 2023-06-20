{ pkgs, config, ... }: {
  # ---------- Tock OS Matrix Synapse Container --------------------------------

  services.nginx.virtualHosts."matrix.tockos.org" = {
    enableACME = true;
    forceSSL = true;

    # Or do a redirect instead of the 404, or whatever is appropriate for you.
    # But do not put a Matrix Web client here! See the Riot Web section below.
    locations."/".extraConfig = ''
      return 404;
    '';

    # forward all Matrix API calls to the synapse Matrix homeserver
    locations."/_matrix" = {
      proxyPass = "http://[::1]:8449"; # without a trailing /
    };
  };

  # PostgreSQL `enable` set in main machine configuration, alongside
  # persistent file system mount.
  services.postgresql = {
    # The ensure-mechanisms don't provide us with the ability to set
    # LC_* locales, hence provide this initialScript instead:
    # initialScript = pkgs.writeText "synapse-init.sql" ''
    #   CREATE ROLE "tockos-synapse" WITH LOGIN PASSWORD 'synapse';
    #   CREATE DATABASE "tockos-synapse" WITH OWNER "tockos-synapse"
    #     TEMPLATE template0
    #     LC_COLLATE = "C"
    #     LC_CTYPE = "C";
    # '';

    # ensureDatabases = [ "tockos-synapse" ];
    # ensureUsers = [{
    #   name = "tockos-synapse";
    #   ensurePermissions = { "DATABASE 'tockos-synapse'" = "ALL PRIVILEGES"; };
    # }];
  };

  fileSystems."/var/lib/nixos-containers/tockos-synapse" = {
    device = "rpool/state/tockos-synapse-container";
    fsType = "zfs";
  };

  containers.tockos-synapse = {
    autoStart = true;

    # We use a container mostly to be able to run multiple synapse-instances on
    # on the same NixOS host, using its services.matrix-synapse module. Thus,
    # don't use a separate network namespace.
    privateNetwork = false;

    config = let
      hostConfig = config;
    in { pkgs, lib, config, ... }: {
      disabledModules = [
        "services/matrix/synapse.nix"
      ];

      imports = [
        ./matrix-synapse-patched/synapse.nix
      ];

      services.matrix-synapse = {
        enable = true;
        overrideLocalPostgresCheck = true;
        settings = {
          server_name = "tockos.org";
          public_baseurl = "https://matrix.tockos.org/";
          enable_registration = false;
          # registration_shared_secret_path = "/var/lib/matrix-synapse/registration_secret";
          user_directory = {
            enabled = false;
            search_all_users = true;
            prefer_local_users = true;
          };
          allow_public_rooms_over_federation = true;
          listeners = [ {
            port = 8449;
            bind_addresses = [ "::1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [ {
              names = [ "client" "federation" ];
              compress = false;
            } ];
          } ];
          database = {
            name = "psycopg2";
            args = {
              user = "tockos-synapse";
              password = "synapse";
              database = "tockos-synapse";
              host = "localhost";
              port = 5432;
            };
          };
        };
      };

      system.stateVersion = hostConfig.system.stateVersion;
    };
  };
}
