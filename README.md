# Aura for NixOS

A Nix flake for [Aura](https://ordreth.com/apps/aura), a lightweight, customizable, offline-first music
player.

Aura is closed source and free to use. This flake does not build it: it takes the official Linux package
(`Aura_<version>_amd64.deb`, the same file as on ordreth.com/apps/aura), checks it against the published
SHA-256, and fits it to NixOS (its libraries come from nixpkgs). That is why it only exists for
`x86_64-linux`.

## Allow Aura (it is unfree)

Aura's license lets you use it at no cost but not redistribute it, so nixpkgs counts it as **unfree**. The
flake's own `nix run` and `nix profile` outputs already allow it. With the NixOS module, the home-manager
module or the overlay, allow it in your configuration, either just Aura:

```nix
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "aura" ];
```

or everything unfree (`nixpkgs.config.allowUnfree = true;`).

## Try it

```sh
nix run github:ordreth/aura-nix
```

## Install

### NixOS

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aura = {
      url = "github:ordreth/aura-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, aura, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        aura.nixosModules.default
        { programs.aura.enable = true; }
      ];
    };
  };
}
```

### home-manager

```nix
{
  imports = [ inputs.aura.homeManagerModules.default ];
  programs.aura.enable = true;
}
```

### Overlay or package

```nix
nixpkgs.overlays = [ inputs.aura.overlays.default ];
environment.systemPackages = [ pkgs.aura ];
```

or, without the overlay, `inputs.aura.packages.x86_64-linux.default`.

### Profile

```sh
nix profile install github:ordreth/aura-nix
```

### Without flakes

```sh
NIXPKGS_ALLOW_UNFREE=1 nix-env -f https://github.com/ordreth/aura-nix/archive/main.tar.gz -iA aura
```

## Getting new versions

Aura does not update itself when installed through Nix: the version arrives when this flake is bumped,
usually within a day or two of a release (a scheduled job opens the pull request, and it is merged once the
new build has been run). If you turn on update checks in
Aura (Settings → About → Updates), it tells you when a new version is out and how to get it, but it never
downloads or installs anything in a Nix build.

```sh
nix flake update aura                  # in your config's folder, then rebuild (nixos-rebuild / home-manager switch)
nix profile upgrade aura-nix           # for a profile install (the name `nix profile list` shows)
```

## Options

Both modules have the same two options:

| Option | Default | |
|---|---|---|
| `programs.aura.enable` | `false` | Install Aura. |
| `programs.aura.package` | Aura from this flake | The package to install. |

Aura keeps its settings and library database in your home folder, like on any other system; the
modules do not manage them.

## Updating to a new Aura release

For the maintainers. Every day, `.github/workflows/update.yml` reads Aura's update manifest
(`ordreth.com/apps/aura/updates/latest.json`), checks its minisign signature against `aura-update.pub` (the
same public key Aura is built with), downloads the `.deb` it names and checks its SHA-256, runs `update.sh`
and opens a pull request. Check it out, then:

```sh
nix build .#aura && ./result/bin/aura-player
```

and merge. By hand:

```sh
./update.sh <version> <sha256>   # the SHA-256 from the release's SHA256SUMS-linux.txt
nix build .#aura && ./result/bin/aura-player
```

Without the SHA-256, `update.sh` downloads the file and hashes it, which only proves it is what the site
serves today. Prefer the published checksum (or the signed manifest, as the job does).

## Help and license

Using Aura: [the user guides](https://ordreth.com/apps/aura). Problems: contact@ordreth.com.

Two licenses apply, to different things:

- **The Nix files in this repository** are under the [MIT license](LICENSE).
- **Aura itself**, the program this flake downloads, is not: it is free to use, closed source, and covered
  by its own [license agreement](https://ordreth.com/apps/aura/terms) and
  [privacy policy](https://ordreth.com/apps/aura/privacy). The agreement allows this flake to adapt the
  program to NixOS (section 2); it does not allow you to redistribute Aura, so do not push it to a public
  binary cache.
