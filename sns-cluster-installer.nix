let
  nixpkgs = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs";
    ref = "nixos-22.11";
    rev = "7dc71aef32e8faf065cb171700792cf8a65c152d";
  };

  pkgs = import nixpkgs {};

  snsClusterConfigGit = nixosVersion:
    pkgs.stdenvNoCC.mkDerivation rec {
      name = "sns-cluster-config";

      src = ./.;

      nativeBuildInputs = with pkgs; [ makeWrapper ];
      buildInputs = with pkgs; [
        coreutils util-linux parted dosfstools zfs mount iproute2 gnused git
        envsubst nixosVersion
      ];

      buildPhase = ''
        echo "Checking whether there are any uncommitted changes or untracked files."
        git update-index --refresh
        git diff-index --quiet HEAD --
        test "$(git ls-files --exclude-standard --others | wc -l)" -lt 1

        # Remove files ignored by git
        git clean -dfX
      '';

      installPhase = ''
        cp -rf ./ $out
      '';

      postFixup = ''
        wrapProgram $out/sns-cluster-install.sh \
          --set PATH ${pkgs.lib.makeBinPath buildInputs}
      '';
    };

  targetSystem = import "${nixpkgs}/nixos" {
    configuration = { config, pkgs, lib, modulesPath, ... }: {
      imports = [
        (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

        # Provide an initial copy of the NixOS channel so that the user
        # doesn't need to run "nix-channel --update" first.
        (modulesPath + "/installer/cd-dvd/channel.nix")
      ];

      system.activationScripts."symlink-sns-cluster-config-root" = let
        nixosVersion =
          lib.findSingle
            (pkg: pkg.name == "nixos-version")
            null null
            config.environment.systemPackages;
        nixosVersionFoundAssert =
          lib.assertMsg
            (nixosVersion != null)
            "nixos-version not found in the target system's environment.systemPackages!";
      in ''
        # DUMMY: ensure the nixos-version assertion is evaluated:
        # ${builtins.toString nixosVersionFoundAssert}
        ln -s ${snsClusterConfigGit nixosVersion} /root/sns-cluster-config
      '';
    };
  };

in
  targetSystem.config.system.build.isoImage
