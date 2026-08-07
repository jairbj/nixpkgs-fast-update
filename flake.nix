{
  description = "Faster-than-nixpkgs packages from official prebuilt binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          packages = {
            grok-build = pkgs.callPackage ./pkgs/grok-build/package.nix { };
            claude-code = pkgs.callPackage ./pkgs/claude-code/package.nix { };
          };
        in
        packages
        // {
          default = packages.grok-build;
        }
      );

      overlays.default = final: _prev: {
        grok-build = final.callPackage ./pkgs/grok-build/package.nix { };
        claude-code = final.callPackage ./pkgs/claude-code/package.nix { };
      };

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          grok-build = self.packages.${system}.grok-build;
          claude-code = self.packages.${system}.claude-code;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              curl
              jq
              nix-prefetch-scripts
              nix-update
            ];
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
