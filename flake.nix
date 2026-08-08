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
            pad = pkgs.callPackage ./pkgs/pad/package.nix { };
            code-server = pkgs.callPackage ./pkgs/code-server/package.nix { };
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
        pad = final.callPackage ./pkgs/pad/package.nix { };
        code-server = final.callPackage ./pkgs/code-server/package.nix { };
      };

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          grok-build = self.packages.${system}.grok-build;
          claude-code = self.packages.${system}.claude-code;
          pad = self.packages.${system}.pad;
          code-server = self.packages.${system}.code-server;
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
