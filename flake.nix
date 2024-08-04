{
  description = "haskell-language-server development flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=ec257526b94d15fb29580fcc19271618ba1f00e1";
    flake-utils.url = "github:numtide/flake-utils";
    # for default.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowBroken = true;
            };
          };

          docs = pkgs.stdenv.mkDerivation {
            name = "hls-docs";
            src = pkgs.lib.sourceFilesBySuffices ./. [
              ".py"
              ".rst"
              ".md"
              ".png"
              ".gif"
              ".svg"
              ".cabal"
            ];
            buildInputs = with pkgs; [ bun ];
            # -n gives warnings on missing link targets, -W makes warnings into errors
            buildPhase = ''cd docs; sphinx-build -n -W . $out'';
            dontInstall = true;
          };

          mkDevShell =
            hpkgs:
            with pkgs;
            mkShell {
              name = "haskell-language-server-dev-ghc${hpkgs.ghc.version}";
              # For binary Haskell tools, we use the default nixpkgs GHC
              # This removes a rebuild with a different GHC version
              # The drawback of this approach is that our shell may pull two GHC
              # version in scope.
              buildInputs = with pkgs; [ bun ];

              shellHook = ''
                export LD_LIBRARY_PATH=${gmp}/lib:${zlib}/lib:${ncurses}/lib:${capstone}/lib
                export DYLD_LIBRARY_PATH=${gmp}/lib:${zlib}/lib:${ncurses}/lib:${capstone}/lib
                export PATH=$PATH:$HOME/.local/bin
              '';
            };

        in
        with pkgs;
        rec {
          # Developement shell with only dev tools
          devShells = {
            default = mkDevShell pkgs.haskellPackages;
          };

          packages = {
            docs = docs;
          };

          # The attributes for the default shell and package changed in recent versions of Nix,
          # these are here for backwards compatibility with the old versions.
          devShell = devShells.default;
        }
      );

}
