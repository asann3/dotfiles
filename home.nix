{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:

{
  home.username = "${userConfig.user}";
  home.homeDirectory = "/Users/${userConfig.user}";

  home.packages = with pkgs; [
    # terminal emulator
    ghostty-bin

    # AI tools
    claude-code

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
    inetutils # telnet etc
    awscli2

    # media
    yt-dlp
    ffmpeg

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
      credential.helper = "osxkeychain";
      core.excludesFile = "~/.config/git/ignore";
    };
  };

  # macOS keyboard shortcuts (com.apple.symbolichotkeys).
  # -dict-add touches only the listed IDs; other shortcuts are preserved.
  home.activation.symbolicHotkeys =
    let
      shift = 131072;
      control = 262144;
      ctrlShift = control + shift;
      sym = ''/usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add'';
      # XML plist keeps integer/bool types; legacy "{a=b;}" stores strings and is ignored by WindowServer
      bind = id: char: code: mods:
        ''run ${sym} ${toString id} '<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>${toString char}</integer><integer>${toString code}</integer><integer>${toString mods}</integer></array></dict></dict>' '';
      disable = id: ''run ${sym} ${toString id} '<dict><key>enabled</key><false/></dict>' '';
    in
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      # Mission Control: move left / right a space (Ctrl+Shift+H / Ctrl+Shift+L)
      ${bind 79 104 4 ctrlShift}
      ${bind 81 108 37 ctrlShift}

      # Accessibility shortcuts: disable all
      ${lib.concatMapStringsSep "\n" disable [ 15 17 19 21 23 25 26 59 162 179 ]}

      run --quiet /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
    '';

  home.file.".amethyst.yml".source = ./.amethyst.yml;
  home.file.".config/git/ignore".source = ./.config/git/ignore;

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
