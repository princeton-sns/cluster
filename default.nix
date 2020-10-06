with builtins;
let
  utils = import ./utils;
  machines = utils.modulesIn ./machines;
  baseSNSMachine = n: (import ./machines/common.nix) { hostname = "sns${n}"; };
  baseMachines = listToAttrs
                  (map (n: let ns = toString n; in { name = "sns${ns}"; value = baseSNSMachine ns; })
                    (genList (n: n + 1) 100));
in baseMachines // machines
