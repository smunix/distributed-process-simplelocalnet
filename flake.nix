{
  description = "Simple zero-configuration backend for Cloud Haskell";
  inputs = {
    np.url = "github:nixos/nixpkgs/haskell-updates";
    fu.url = "github:numtide/flake-utils/master";
    dp.url =
      "git+file:///home/smunix/Programming/smunix.distrib/distributed-process?ref=1-nix-build";
  };
  outputs = { self, np, fu, dp }:
    with fu.lib;
    with np.lib;
    eachSystem [ "x86_64-linux" ] (system:
      let
        version =
          "${substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
        mkOverlay = { package }:
          final: _:
          with final;
          with haskell.lib;
          with haskellPackages.extend (self: _: with self; rec { }); {
            "${package}" = overrideCabal (doJailbreak
              (callCabal2nix "${package}" ./. {
                distributed-process = final.distributed-process;
              })) (o: { version = "${o.version}.${version}"; });
          };
        overlays = [
          (mkOverlay { package = "distributed-process-simplelocalnet"; })
          dp.overlay.${system}
        ];
        config = { };
      in with (import np { inherit system overlays config; }); rec {
        packages = flattenTree
          (recurseIntoAttrs { inherit distributed-process-simplelocalnet; });
        defaultPackage = packages.distributed-process-simplelocalnet;
      });
}
