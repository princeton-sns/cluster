{ machine, nixos ? import <nixos/nixos> }:

let
  configuration = { ... }:
    {
      users.users."operator" = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [ (builtins.readFile ./operator.pub) ];
      };
      imports =
        [
          (import ../.)."${machine}"
        ];
    };
in (nixos { inherit configuration; }).vm

