{ config, pkgs, userConfig, ... }:

{
  home.username = "${userConfig.user}";
  home.homeDirectory = "/Users/${userConfig.user}";

  home.packages = with pkgs; [
    git
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
