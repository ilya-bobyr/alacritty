# Alacritty

## Nix support

I've taken `default.nix` from

https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/applications/terminal-emulators/alacritty/default.nix

renamed it to `package.nix`, with a few minor changes to use `./.` as the
source.  Then updated how man pages are generated and removed the default
configuration file example.  Those are changes between 0.12 and 0.14.

## How to configure and install

```bash
nix build '.#my-alacritty'
```

## Now to add into a `nix profile`

```bash
nix profile install '.#my-alacritty'
```

## OpenGL compatibility

Alacritty uses OpenGL and it does not work in isolation from the host
distribution.  Meaning that nixpkgs programs that use OpenGL do not work
correctly on Ubuntu and other non-NixOS distributions without additional help.

<https://nixos.wiki/wiki/Nixpkgs_with_OpenGL_on_non-NixOS>

<https://github.com/NixOS/nixpkgs/issues/9415>

I've decided to use [`nixGL`](https://github.com/nix-community/nixGL).  And to
create a wrapper for the Alacritty binary, that would hide the `nixGL`
invocation, allowing me to call Alacritty as if no wrapping is happening.

TODO: Figure out how to write the wrapper correctly.  I think a number of
packages in the nixpkgs tree use wrappers.  Firefox and Thunderbird, for
example.  Do they server the same purpose?  If so, it could make sense to write
this wrapper in the same manner.
