{
  description = "AWS infrastructure for the Chai Solutions organization";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    flake-parts,
    nixpkgs,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        _module.args = {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        };

        devShells.default = pkgs.mkShell {
          name = "chai-solutions-infra-shell";
          packages = with pkgs; [
            awscli2
            openssl
            terraform

            colmena
          ];
        };
      };
    };
}
