{
  description = "Aura, a lightweight, customizable, offline-first music player, for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # The only Linux package Aura publishes is amd64.
      system = "x86_64-linux";

      # Aura is unfree (free to use, no redistribution). The flake's own outputs allow it, and only
      # it, so `nix run` works without touching the user's config. The overlay and the modules use
      # the user's nixpkgs, where they allow it themselves (README).
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "aura";
      };
    in
    {
      packages.${system} = rec {
        aura = pkgs.callPackage ./package.nix { };
        default = aura;
      };

      apps.${system}.default = {
        type = "app";
        program = nixpkgs.lib.getExe self.packages.${system}.aura;
        meta.description = "Run Aura";
      };

      overlays.default = final: _prev: {
        aura = final.callPackage ./package.nix { };
      };

      nixosModules = rec {
        aura = ./modules/nixos.nix;
        default = aura;
      };

      homeManagerModules = rec {
        aura = ./modules/home-manager.nix;
        default = aura;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
