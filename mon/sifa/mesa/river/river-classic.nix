{ ... }:
{
  flake.nixosModules.river-classic =
  { lib, config, inputs, ... }:
  let
    opsyon = config.drevosim.sifa.mesa.river-classic;
  in
  {
    options.drevosim.sifa.mesa.river-classic = {
      enable = lib.mkEnableOption "River-Classic compositor";
      init = lib.mkOption {
        type = lib.types.path;
        default = ./faylu/river-classic.sh;
        defaultText = lib.literalExpression ''
          ./faylu/river-classic.sh
        '';
        description = ''
          Path to the init script for the river-classic wayland compositor.
        '';
      };
    };
    opsyon.wrapped = lib.mkIf opsyon.enable (
      inputs.wrapper-modules.lib.evalPackage
      ({ pkgs, wlib, ... }:
      {
        inherit pkgs;
        imports = [ wlib.modules.default ];
        package = pkgs.river-classic;
        files."share/river/init".source = config.init;
        env.XDG_CONFIG_HOME = "${placeholder "out"}/share";
      })
    );
  };
}
