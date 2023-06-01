{ config, lib, pkgs, ... }:

let
  fqdn =
    let
      join = hostName: domain: "${hostName}.${domain}";
    in join config.networking.hostName config.networking.domain;
in {
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    # only recommendedProxySettings and recommendedGzipSettings are strictly required,
    # but the rest make sense as well
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."princeton.systems" = {
      enableACME = true;
      forceSSL = true;
      locations."= /.well-known/matrix/server".extraConfig =
        let
          # use 443 instead of the default 8448 port to unite
          # the client-server and server-server port for simplicity
          server = { "m.server" = "matrix.princeton.systems:443"; };
        in ''
          add_header Content-Type application/json;
          return 200 '${builtins.toJSON server}';
        '';
      locations."= /.well-known/matrix/client".extraConfig =
        let
          client = {
            "m.homeserver" =  { "base_url" = "https://matrix.princeton.systems"; };
            "m.identity_server" =  { "base_url" = "https://vector.im"; };
          };
        # ACAO required to allow riot-web on any URL to request this json file
        in ''
          add_header Content-Type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON client}';
        '';
    };

    virtualHosts."${fqdn}" = {
      enableACME = true;
      forceSSL = true;
      # Or do a redirect instead of the 404, or whatever is appropriate for you.
      # But do not put a Matrix Web client here! See the Riot Web section below.
      locations."/".extraConfig = ''
        return 404;
      '';

      # forward all Matrix API calls to the synapse Matrix homeserver
      locations."/_matrix" = {
        proxyPass = "http://sns26.cs.princeton.edu:8448"; # without a trailing /

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

    virtualHosts."chat.princeton.systems" = {
      enableACME = true;
      forceSSL = true;
      root = pkgs.element-web.override {
        conf = {
          default_server_config."m.homeserver" = {
            "base_url" = "https://${fqdn}";
            "server_name" = "princeton.systems";
          };
        };
      };
    };
  };

  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    '';
  };

  services.matrix-synapse = {
    enable = false;
    package = pkgs.matrix-synapse.overrideDerivation (oldAttrs: {
      patches = [./matrix-synapse-localpart.patch];
      doCheck = false;
    });
    settings = {
      #federation_domain_whitelist = [ "matrix.org" "mozilla.org" "nixos.org" "is.currently.online" ];
      server_name = "princeton.systems";
      public_baseurl = "https://${fqdn}/";
      #account_threepid_delegates = {
      #  email = "https://vector.im";
      #};
      enable_registration = false;
      password_config.enabled = false;
      cas_config = {
        enabled = true;
        server_url = "https://fed.princeton.edu/cas";
        service_url = "https://${fqdn}";
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
      listeners = [
        {
          port = 8448;
          bind_addresses = ["::1"];
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
}
