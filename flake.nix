{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    preservation.url = "github:nix-community/preservation";
    nix-maid.url = "github:viperML/nix-maid";
    import-tree.url = "github:vic/import-tree";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SillyTavern third-party extensions. Tracked via flake.lock — refresh
    # one with `nix flake update sillytavern-<name>` or all with
    # `nix flake update`. They are plain git repos, not flakes.
    sillytavern-characterlibrary = {
      url = "github:Sillyanonymous/SillyTavern-CharacterLibrary";
      flake = false;
    };
    sillytavern-topinfobar = {
      url = "github:SillyTavern/Extension-TopInfoBar";
      flake = false;
    };
    sillytavern-quickpersona = {
      url = "github:SillyTavern/Extension-QuickPersona";
      flake = false;
    };
    sillytavern-promptinspector = {
      url = "github:SillyTavern/Extension-PromptInspector";
      flake = false;
    };
    sillytavern-typingindicator = {
      url = "github:SillyTavern/Extension-TypingIndicator";
      flake = false;
    };
    sillytavern-notebook = {
      url = "github:SillyTavern/Extension-Notebook";
      flake = false;
    };
    sillytavern-objective = {
      url = "github:SillyTavern/Extension-Objective";
      flake = false;
    };
    sillytavern-ultimate-chatassistant = {
      url = "github:BobTheBinChicken/Ultimate-ChatAssistant";
      flake = false;
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { inherit inputs; }
    (inputs.import-tree.filterNot (p: inputs.nixpkgs.lib.hasInfix "/faylu/" p) ./mon);
}
