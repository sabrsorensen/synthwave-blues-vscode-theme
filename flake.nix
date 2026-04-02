{
  description = "Synthwave Blues VS Code Theme - Development environment and baked VS Code derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Unified approach for handling unfree packages
        pkgsAllowUnfree = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.legacyPackages.${system}.lib.getName pkg) [
            #"vscode"
            #"vscode-extension-MS-python-python"
            #"vscode-extension-ms-vscode-cpptools"
            #"vscode-extension-ms-vsliveshare-vsliveshare"
          ];
        };
        pkgs = pkgsAllowUnfree;

        # Extension metadata
        packageJson = builtins.fromJSON (builtins.readFile ./package.json);
        extensionName = "synthwave-blues";
        extensionVersion = packageJson.version;

        # Vendor npm dependencies for reproducible builds
        npmDeps = pkgs.fetchNpmDeps {
          name = "synthwave-blues-npm-deps";
          src = ./.;
          hash = "sha256-GwI0nRWALqhMiYgEqlBSctVE3ns0neM8ZwUsvubBSiM=";
        };

        # Only include files needed for the build — excludes .git, build artifacts, etc.
        src = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./.vscodeignore
            ./src
            ./themes
            ./icon.png
            ./package.json
            ./README.md
            ./LICENSE
            ./CONTRIBUTING.md
          ];
        };

        bakedSrc = src // pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./patches
            ./scripts
          ];
        };

        # Build the VS Code extension
        synthwave-blues-extension = pkgs.stdenv.mkDerivation {
          pname = "${extensionName}-vscode-extension";
          version = extensionVersion;

          inherit src npmDeps;

          nativeBuildInputs = with pkgs; [ nodejs vsce ];

          buildPhase = ''
            # Use vendored node_modules for reproducible builds
            if [ -d "$npmDeps" ]; then
              cp -r $npmDeps node_modules
            fi
            # Package the extension as .vsix
            vsce package --no-git-tag-version --skip-license --no-update-package-json --allow-star-activation --no-dependencies --out synthwave-blues.vsix
          '';

          installPhase = ''
            mkdir -p $out/share/vscode/extensions/${extensionName}
            cp -r . $out/share/vscode/extensions/${extensionName}/
            # Copy the .vsix file to $out
            mkdir -p $out/vsix
            cp synthwave-blues.vsix $out/vsix/
          '';
        };

        # Pre-patched VS Code with Synthwave Blues theme built-in
        synthwave-blues-vscode = pkgs.vscode.overrideAttrs (oldAttrs: {
          pname = "vscode-${extensionName}";
          version = "${oldAttrs.version}-vsc-${extensionVersion}-swb";
          __intentionallyOverridingVersion = true;

          inherit bakedSrc;

          buildInputs = (oldAttrs.buildInputs or []) ++ [ pkgs.jq pkgs.openssl ];

          installPhase = (oldAttrs.installPhase or "") + (builtins.readFile (pkgs.replaceVars ./scripts/inject-theme.sh {
            SYNTHWAVE_BLUES_EXTENSION = synthwave-blues-extension;
            EXTENSION_NAME = extensionName;
            PATCHES_DIR = "${self}/patches";
            PATCH_BIN = "${pkgs.patch}/bin/patch";
            JQ_BIN = "${pkgs.jq}/bin/jq";
          }));

          # Fix wrapGAppsHook unbound variable bug - initialize to empty so hook can run normally
          # Hook will respect dontWrapGApps=true and skip wrapping while avoiding [ -z "$var" ] error
          preFixup = ''
            wrapGAppsHookHasRun=""
          '' + (oldAttrs.preFixup or "");

          # Recalculate checksums in postFixup
          postFixup = (oldAttrs.postFixup or "") + (builtins.readFile (pkgs.replaceVars ./scripts/update-checksums.sh {
            JQ_BIN = "${pkgs.jq}/bin/jq";
            OPENSSL_BIN = "${pkgs.openssl}/bin/openssl";
          }));
        });

      in {
        packages = {
          default = synthwave-blues-extension;
          extension = synthwave-blues-extension;
          vscode-synthwave-blues = synthwave-blues-vscode;
        };

        devShells.default =
          let devEnv = import ./dev-env.nix { pkgs = pkgs; };
          in pkgs.mkShell {
            inherit (devEnv) buildInputs shellHook;
          };

        apps = {
          package-extension = {
            type = "app";
            program = "${pkgs.writeShellScript "package-${extensionName}" ''
              ${pkgs.vsce}/bin/vsce package
            ''}";
            meta = {
              description = "Package SynthWave Blues VS Code theme extension as .vsix file";
              license = nixpkgs.lib.licenses.mit;
            };
          };
        };
      });
}
