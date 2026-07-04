# Custom RPCS3 Nix Flake

A self-contained Nix Flake designed to build the bleeding-edge `master` branch of the RPCS3 PlayStation 3 emulator.

## 🖥️ NixOS System Integration

This flake exposes a customized NixOS module that handles package delivery, licenses, and configures the hardware `udev` rules required for PlayStation 3, 4, and DualSense controllers automatically.

### 1. Add this Flake to your System Inputs
Open your main system configuration directory and modify its `flake.nix` to include this repository as an upstream input tracking reference:

```nix
{
  description = "My Main NixOS System Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    rpcs3-flake = {
        url = "github:yourusername/rpcs3-flake";
        inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, rpcs3-flake, ... }@inputs: {
    nixosConfigurations.yourHostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; # Pass inputs to configuration.nix
      modules = [ ./configuration.nix ];
    };
  };
}
```

### 2. Activate the Module in `configuration.nix`
Open your `configuration.nix` file and import the default exposed module. This automatically hooks up the software and its respective `udev` device rules:

```nix
{ config, pkgs, inputs, ... }: {

  imports = [
    # Instantly registers the overlay, packages, and hardware rules
    inputs.rpcs3-flake.nixosModules.default
  ];

  # Essential: Permit unfree licenses since RPCS3 packages reference unfree assets
  nixpkgs.config.allowUnfree = true;
}
```

### 3. Rebuild Your System
Apply your modifications by running your traditional profile switch sequence:
```bash
sudo nixos-rebuild switch --flake .#yourHostname
```

---

## 🔄 Routine Upkeep

When you want to pull down the newest emulation enhancements from the upstream developers:

1. Navigate to this directory (`~/rpcs3-flake`).
2. Fetch the newest snapshot reference and commit the updated tracking layout:
   ```bash
   nix flake update rpcs3-src
   git commit -am "chore: bump rpcs3 upstream revision"
   ```
3. Navigate back to your system configuration file path and update the input references to lock onto your repository modifications:
   ```bash
   nix flake update rpcs3-flake
   sudo nixos-rebuild switch --flake .#yourHostname
   ```
