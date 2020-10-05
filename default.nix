let
  utils = import ./utils.nix;
  machines = utils.modulesIn ./machines;
in machines
