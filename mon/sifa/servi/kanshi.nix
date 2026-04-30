{ self, inputs, ... }:
{
  flake.nixosModules.kanshi = 
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      kanshi
      wlr-randr
    ];
    users.users.eter.maid = {
      file.xdg_config."kanshi/config" = {
        text = ''
	  profile undocked {
	    output eDP-1 enable
	  }
	  profile docked {
	    output eDP-1 disable
	    output DP-1 enable position 0,0
	  }
	'';
      };
      systemd.services.kanshi = {
        description = "Kanshi servi";
	partOf = [ "graphical-session.target" ];
	after = [ "graphical-session.target" ];
	serviceConfig = {
	  ExecStart = "${pkgs.kanshi}/bin/kanshi";
	  Restart = "always";
	};
	wantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
