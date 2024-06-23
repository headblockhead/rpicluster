{
  description = "A flake that generates a TFTP folder to serve Raspberry Pi clients with a NixOS image";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }@ inputs:
    let
      inherit (self) outputs;
      sshkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvr2FrC9i1bjoVzg+mdytOJ1P0KRtah/HeiMBuKD3DX";
    in
    rec{
      # Example System config
      nixosConfigurations = {
        rpi-cluster-01 = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs sshkey nixpkgs;
            systemname = "rpi-cluster-01";
            systemserial = "01-dc-a6-32-31-50-3b"; # systemserial can also be set to "default" to boot any system that requests a netboot.
          };
          system = "x86_64-linux";
          modules = [
            {
              nixpkgs.config.allowUnsupportedSystem = true;
              nixpkgs.crossSystem.system = "aarch64-linux"; # Target system
            }

            nixosModules.default
            ./client/config.nix
            ./client/hardware.nix # Shared hardware configuration for Raspberry Pis
          ];
        };
      };
      nixosModules.default = { config }: {
        imports = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
          ./genTFTP.nix
        ];
      };
      rpi-01-tftp = nixosConfigurations.rpi-cluster-01.config.system.build.rpiTFTP;
      #      NFSFolder = nixosConfigurations.client.config.system.build.sdImage;
    };
}

