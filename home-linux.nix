{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:

let
  gitWithLibsecret = pkgs.git.override { withLibsecret = true; };
in
{
  home.username = "${userConfig.user}";
  home.homeDirectory = "/home/${userConfig.user}";

  home.packages = with pkgs; [
    # AI tools
    claude-code

    # shell / terminal
    tmux
    tree
    htop
    coreutils
    vim

    # git
    gh

    # python
    uv

    # dev tools
    cmake
    ccache
    llvmPackages.lld
    clang-tools # provides clang-format
    nixfmt
    nil

    # security / reversing
    binwalk
    gdb
    radare2

    # hardware / serial / SDR
    picocom
    lrzsz
    avrdude
    uhd

    # network
    wireguard-tools
    inetutils

    # media
    ffmpeg

    # GNOME extensions
    gnomeExtensions.night-theme-switcher
  ];

  programs.git = {
    enable = true;
    package = gitWithLibsecret;
    lfs.enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      credential.helper = "${gitWithLibsecret}/bin/git-credential-libsecret";
      core.excludesFile = "~/.config/git/ignore";
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
    mutableExtensionsDir = false;
  };

  home.file = {
    ".tmux.conf".source = ./.tmux.conf;
    ".vimrc".source = ./.vimrc;
    ".config/git/ignore".source = ./.config/git/ignore;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Yaru-dark";
    };
  };

  programs.home-manager.enable = true;
  programs.fish = {
    enable = true;
    shellInit = ''
      fish_add_path ~/.local/bin
    '';
    interactiveShellInit = ''
      if status is-interactive
        and not set -q TMUX
        and test "$TERM_PROGRAM" != "vscode"
        set session_name "temp-"(date +%s)"-"$fish_pid
        tmux new-session -s $session_name \; set-option destroy-unattached on
      end
    '';
  };

  home.stateVersion = "25.11";
}
