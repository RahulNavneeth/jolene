{
  description = "joylene";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { inherit system; }));
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ zig_0_15 cmake pkg-config ]
            ++ lib.optionals stdenv.hostPlatform.isLinux [ alsa-lib ]
            ++ lib.optionals stdenv.hostPlatform.isDarwin [ apple-sdk ];
        };
      });
    };
}
