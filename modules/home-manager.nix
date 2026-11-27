# `programs.aura` for home-manager: installs Aura for one user.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aura;
in
{
  options.programs.aura = {
    enable = lib.mkEnableOption "Aura, a lightweight, customizable, offline-first music player";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../package.nix { };
      defaultText = lib.literalExpression "aura (from the aura-nix flake)";
      description = "The Aura package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
