# Without flakes: `nix-build -A aura`, or `nix-env -f . -iA aura` (needs `allowUnfree` or a predicate that
# allows "aura" in ~/.config/nixpkgs/config.nix).
{
  pkgs ? import <nixpkgs> { },
}:

{
  aura = pkgs.callPackage ./package.nix { };
}
