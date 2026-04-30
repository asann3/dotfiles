{ config, pkgs, userConfig, ... }:

{
  home.username = "${userConfig.user}";
  home.homeDirectory = "/Users/${userConfig.user}";

  home.packages = with pkgs; [
    # shell / terminal
    tmux
    tree
    htop
    ripgrep
    wget
    coreutils
    gnused
    vim

    # git
    gh

    # python
    uv

    # rust
    rustc
    cargo

    # document / publish
    pandoc
    typst
    ghostscript
    poppler
    mupdf
    exiftool
    imagemagick
    librsvg
    gnuplot
    hugo

    # dev tools
    cmake
    ccache
    swig
    llvmPackages.lld

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
    inetutils # telnet etc
    awscli2

    # media
    yt-dlp

    # container
    colima

    # disk / recovery
    testdisk

    # infra
    ansible
    ollama

    # misc
    sl
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.home-manager.enable = true;
  programs.fish = {
    enable = true;
    shellAliases = {
      brew-x86 = "arch -x86_64 /usr/local/bin/brew";
    };

    shellInit = ''
      fish_add_path ~/bin/xelatex
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
