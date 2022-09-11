{ hostname }:
{ config, pkgs, ... }:

{
  networking.hostName = hostname; # Define your hostname.
  networking.domain = "cs.princeton.edu";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.fail2ban.enable = true;
  # Allow passwordless `sudo` when logged in with SSH
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    curl wget vim ipmitool
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  system.autoUpgrade = {
    enable = true;
    dates = "hourly";
  };

  # Garbage collect nix store weekly
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Also collect garbage if disk has less than 100MB free
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (2 * 1024 * 1024 * 1024)}
    '';
  };
}

