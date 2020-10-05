with builtins;
{
  githubSSHKeys = user: map (record: record.key) (
    fromJSON (
      readFile (fetchurl "https://api.github.com/users/${user}/keys")
    )
  );
  modulesIn = dir:
    let
      nameValuePair = attr: {
        name = removeDotNix attr; value = (import (dir + "/${attr}"));
      };
      nixOnly = filter (name: substring (stringLength name - 4) (stringLength name) name == ".nix");
      removeDotNix = name: substring 0 (stringLength name - 4) name;
    in listToAttrs ((map nameValuePair) (nixOnly (attrNames (readDir dir))));
}
