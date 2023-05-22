{ installerTarget ? "isoImage", kexecRootSSHKey ? null }:

let
  nixpkgs = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs";
    ref = "nixos-22.11";
    rev = "7dc71aef32e8faf065cb171700792cf8a65c152d";
  };

  cleverca22NixTests = builtins.fetchGit {
    url = "https://github.com/cleverca22/nix-tests";
    ref = "master";
    rev = "2ba968302208ff0c17d555317c11fd3f06e947e2";
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

  isoImageSystemConfig = { modulesPath, ... }: {
    imports = [
      # Add in the standard module for NixOS install media:
      (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

      # Provide an initial copy of the NixOS channel so that the user
      # doesn't need to run "nix-channel --update" first.
      (modulesPath + "/installer/cd-dvd/channel.nix")
    ];
  };

  kexecSystemConfig = { ... }: {
    imports = [
      # Import cleverca22's kexec NixOS installer config
      "${cleverca22NixTests}/kexec/configuration.nix"
    ];

    # Enable DHCP on all interfaces:
    networking.useDHCP = true;

    kexec.autoReboot = false;

    users.users.root.openssh.authorizedKeys.keys = [
      kexecRootSSHKey
    ];
  };

  targetSystem = import "${nixpkgs}/nixos" {
    configuration = { config, pkgs, lib, modulesPath, ... }: {
      imports = (
        lib.optional
          (installerTarget == "isoImage")
          isoImageSystemConfig
      ) ++ (
        lib.optional
          (installerTarget == "kexec_tarball")
          kexecSystemConfig
      );

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
  targetSystem.config.system.build."${installerTarget}"
