{ pkgs, ... }: {
  # ---------- SNS Group Matrix Synapse ----------------------------------------

  # PostgreSQL `enable` set in main machine configuration, alongside
  # persistent file system mount.
  services.postgresql = {
    # The ensure-mechanisms don't provide us with the ability to set
    # LC_* locales, hence provide this initialScript instead:
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    '';

    # ensureDatabases = [ "matrix-synapse" ];
    # ensureUsers = [{
    #   name = "matrix-synapse";
    #   ensurePermissions = { "DATABASE 'matrix-synapse'" = "ALL PRIVILEGES"; };
    # }];
  };

  fileSystems."/var/lib/matrix-synapse" = {
    device = "ssdpool0/state/matrix-synapse";
    fsType = "zfs";
  };

  services.nginx.virtualHosts."matrix.princeton.systems" = {
    enableACME = true;
    forceSSL = true;
    # Or do a redirect instead of the 404, or whatever is appropriate for you.
    # But do not put a Matrix Web client here! See the Riot Web section below.
    locations."/".extraConfig = ''
      return 404;
    '';

    # forward all Matrix API calls to the synapse Matrix homeserver
    locations."/_matrix" = {
      proxyPass = "http://[::1]:8448"; # without a trailing /

      # Element iOS will send a request to cause Synapse to redirect to the
      # SSO provider with a trailing slash:
      #
      #     /_matrix/client/r0/login/sso/redirect/?...
      #
      # This causes synapse to respond with an M_UNRECOGNIZED error. Thus, for
      # now, explicitly match on that URL and remove the trailing slash. nginx
      # takes care of the query parameters. This looks exactly like issue 4785
      # [1]; however this should have been fixed in all recent versions of
      # Element iOS.
      #
      # [1]: https://github.com/vector-im/element-ios/issues/4785
      extraConfig = ''
        rewrite ^(/_matrix/client/r0/login/sso/redirect)/$ $1 break;
      '';
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      matrix-synapse-unwrapped = prev.matrix-synapse-unwrapped.overrideDerivation (oldAttrs: {
        patches = [./matrix-synapse-localpart.patch];
        doCheck = false;
      });
    })
  ];

  services.matrix-synapse = {
    enable = true;
    settings = {
      #federation_domain_whitelist = [ "matrix.org" "mozilla.org" "nixos.org" "is.currently.online" ];
      server_name = "princeton.systems";
      public_baseurl = "https://matrix.princeton.systems/";
      enable_registration = false;
      password_config.enabled = false;
      cas_config = {
        enabled = true;
        server_url = "https://fed.princeton.edu/cas";
        service_url = "https://matrix.princeton.systems";
        displayname_attribute = "displayname";
      };
      auto_join_rooms = [ "#lobby:princeton.systems" ];
      sso = {
        update_profile_information = false;
      };
      user_directory = {
        enabled = false;
        search_all_users = true;
        prefer_local_users = true;
      };
      account_threepid_delegates = {
        msisdn = "https://vector.im";
      };
      email = {
        smtp_host = "sns26.cs.princeton.edu";
        notif_from = "Princeton Systems %(app)s homeserver <noreply@princeton.systems>";
      };
      listeners = [
        {
          port = 8448;
          bind_addresses = ["::1" "0.0.0.0"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [ "client" "federation" ];
              compress = false;
            }
          ];
        }
      ];
    };
  };

   services.nginx.virtualHosts."chat.princeton.systems" = {
     enableACME = true;
     forceSSL = true;
     root = pkgs.element-web.override {
       conf = {
         default_server_config."m.homeserver" = {
           "base_url" = "https://matrix.princeton.systems";
           "server_name" = "princeton.systems";
         };
       };
     };
   };

  # Temporarily make the matrix-synapse server accessible for proxy_pass from
  # adam.cs.princeton.edu
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp -s 128.112.7.101 --dport 8448 -j ACCEPT
  '';
}

