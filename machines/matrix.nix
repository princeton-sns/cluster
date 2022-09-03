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
          server = { "m.server" = "${fqdn}:443"; };
        in ''
          add_header Content-Type application/json;
          return 200 '${builtins.toJSON server}';
        '';
      locations."= /.well-known/matrix/client".extraConfig =
        let
          client = {
            "m.homeserver" =  { "base_url" = "https://${fqdn}"; };
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
        proxyPass = "http://[::1]:8448"; # without a trailing /
      };
    };
    #virtualHosts."chat.${config.networking.domain}" = {
    #  enableACME = true;
    #  forceSSL = true;
    #  root = pkgs.element-web.override {
    #    conf = {
    #      default_server_config."m.homeserver" = {
    #        "base_url" = "https://${fqdn}";
    #        "server_name" = "${config.networking.domain}";
    #      };
    #    };
    #  };
    #};
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
    enable = true;
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
      sso = {
        update_profile_information = false;
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
