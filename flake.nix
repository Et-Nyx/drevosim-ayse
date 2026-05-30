{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    wrapper-modules.inputs.nixpkgs.follows = "nixpkgs";

    nix-maid.url = "github:viperML/nix-maid";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    kwm-src = {
      url = "github:kewuaa/kwm";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake
  { inherit inputs; }
  (inputs.import-tree ./mon);
}
