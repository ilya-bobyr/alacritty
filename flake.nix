{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      out = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          appliedOverlay = self.overlays.default pkgs pkgs;
        in
        {
          packages.my-alacritty = appliedOverlay.my-alacritty;
        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      overlays.default = final: prev: {
        my-alacritty = final.callPackage ./package.nix { };
      };
    };
}
