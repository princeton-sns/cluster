{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "056f1814";
    hostName = "sns62";

    interfaces.enp4s0f0 = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.gamma = {
      enable = true;

      bootDiskNode = "/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S1ATNSAD725594H";
      bootPartUUID = "070D-17EA";
      swapPartUUID = "35d57daa-feaf-4c37-92d9-3987791de9c1";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # leons
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9XgOJNVpO00+p04GwoL0viFco4p24PrsPzvsCOiAETJ6ttYiOFjYrpjQvNLsDse0PcW+duhtjyyp+Y7JZaOTeG6FX1Y8j6gDCUML58f4NlKtnWzfMftYkVO8QeYzdjJhG3J2zBXuqMmen7elVgZouvM/H47X620q7BssTTS1YIVnXxNn5jip8UbSJ1073MnUuTjSGrmS9yyLQx4Ka9/u6zzPDASw6OWXyzoXkWVpU5VzAqYk8Ob9C+lFQw5LMERsQBADoNB+kg/m+OoKS7XXu9+WFdTKsqhy7/c6hijRPaNsP/JRfsxEyjF+Y8LyokU2OXq0MWM0xZrt8O3/DsXAKqyIrGCVPQX+eeXvqP8LusFm2CDe8zoUeyLXvBdZX6Xxyy00OHHQRsuIbBYCJOUMbmDwIcEaC4DELjcNFZXJQYhj2hvB2sQvTMjnS58FDkD+IgVTTlTTzkEiDwbIV6lHbSqzA6AvZtZXd1+rQ4wFIT0clQhAGpBWKN+8Cotl51yC+P+nbU9xlCXM17Q3Pev2sjZFx1VU3oa5SEzEv74aWhUDCaATun/ebi/1Scm3ekOsiPVHuUBm9a2GUMYIuAOTL6W9AM2zZJ8xWkJw5Rj1eQnIDwD9izCRR1gJXlkTYwLn6ZnLawX6FS6Vvj5NV8mjjU4xlhnwaWF0b/Jmm3E966w=="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGtanFKH41B3/4piGmhl82gh0AsGACkDV85vUcWHJhrY8AkrVSphnrpL62gY7R6/Rx3AZ+6A+GYoICJa/V4qWUkKryOavZ9xe164JeFtFFN/CrDsIWCLdMyvQ5JO0zc5QmUCRX/UfRzjRzf+y6QdnIoNw5tV2E0zQj9g68I7uNEuuYNmQLg2EyoOE0qtxFTMBEcRzocvVx2QoErDOWD17fDhjc1kR7D7lMVI8jIqRFEQQO3ke6YTXkJAVtjjELqcnSERq58qDKZm9HuYtiUe8cgiBe1UdD8lHTwAGbEE1mSV0IsAOxEoo1BkjBhrYqUxPwfObZwt6TkTF/tbuZkU+m4RU09j2FqliXe66cpDeyAs/C88QObsrqCHb3JJa1GtAp8JSeiELadYYKgiVJibVpb8mBksRxeCruk1Jr9DeAmKVeF/tTect9YALD8qTQNnsyBh0r7HMxyBEze5O6RAV2rnjWHxYIj9oBj8V/q+cykEUXfc4M8rHn/dt72h/LcL3jaYvQwecJjOCW2xW2/sGWkhJ7ittPV7aeOcL9TqG6mggukBjgM/TtPFxsjduxNZ2YSUgVHdmaRsfyDDMfXtdjfCdRcCxslRwQTgl8X2Kb5M0CsQSmWas7vb6JhBLyDPYWWJyxSzb98P3flq9qZjQlVaAiP6asYLDSoKMDYoY7Rw=="
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBLRUBvcGp1IPw+c1dBZhe5tpnrd3SwmAPU5NPz0rlVgKrsY0xF6VPRkxx8RiMicT+1lb/gaAgXpjr2gAWOrykx9ICrWOD46LocF7RmYPclhviRoPrIDQ9lr+tgBXVSRKew=="
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBAAEifRTFU66SfUXr7eSsBQW1/znzR05dSDCy9eA8eJIbE4kIjqR1hFTKxI+dc2R6jGQK/DxPzLmg/aIRzH6fankH6gWNjpczP0MC1jgSRCqLTQe+TpyVnQ1f/1fPYCSOQ=="
    "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBKIVUBFIc4BI9yp3gmlCWA4MAm/22rgisu6BJivBfaPq/ELEZChxpfTPIAWMM0UUU53UppWRdI7Q3fdlYommOOAAAAAXaWRfeXViaWtleTVfc2tAYmxpbmsuc2g="

    # alevy
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0UMDPmdytTJ2J1y/FsvReZRFTl7WA2HB0GVMWyUP5R"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBbxJcPHPkhNwCuoa0wJvK4WHT/GVX7g3JjJFTZvXSc6eDgSr6r1oynlNO5jlr68AVAWxbkckfw6TAtdfuCxcrZQe+xMJ0UWmstR5Ed7poAbkU6uSrA8nLI0tl3Swuc87wq/qpX8nkEJR5oAGzNp0ZPTH7kshx3ZE/2n3XXLuyaYme68YhKk3MiVU8jz5J9NUeH4zeTdHKFMnydy4ORg+pVc/8esauQyiITk/SDRXIO56DEnpZQGu96gHVBDwtx8GxbnmEnumKsxiOR3aXbGFVF1FhlDyUKQKqm28GBJyByRiQuDVI06+ZhCLzrq3wiPbtxmctdBcVLP2KpqPYQPWZ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCReHVoVeXfqK8bbIcotwhUBrt7u2T6IQNKMysmJF42"
  ];

  users.users.leons = {
    isNormalUser = true;
    contactEmail = "leon@is.currently.online";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}

