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
    ".xprofile".source = ./.xprofile;
    ".config/xmonad/xmonad.hs".source = ./.config/xmonad/xmonad.hs;
    ".config/xmobar/xmobarrc".source = ./.config/xmobar/xmobarrc;
    ".local/bin/theme-switch".source = ./.local/bin/theme-switch;
    ".config/systemd/user/theme-light.service".source = ./.config/systemd/user/theme-light.service;
    ".config/systemd/user/theme-dark.service".source = ./.config/systemd/user/theme-dark.service;
    ".config/systemd/user/theme-light.timer".source = ./.config/systemd/user/theme-light.timer;
    ".config/systemd/user/theme-dark.timer".source = ./.config/systemd/user/theme-dark.timer;
    ".config/xsettingsd/xsettingsd.conf".source = ./.config/xsettingsd/xsettingsd.conf;
  };

  home.activation.installNightThemeSwitcher = lib.hm.dag.entryAfter ["writeBoundary"] ''
    EXT_ID="nightthemeswitcher@romainvigier.fr"
    EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_ID"

    if [ ! -d "$EXT_DIR" ]; then
      GNOME_VER=$(gnome-shell --version | grep -oP '\d+' | head -1)
      TMP=$(mktemp -d)
      VERSION_TAG=$(${pkgs.curl}/bin/curl -sf \
        "https://extensions.gnome.org/extension-info/?uuid=$EXT_ID&shell_version=$GNOME_VER" \
        | ${pkgs.python3}/bin/python3 -c \
          'import sys,json; print(json.load(sys.stdin)["version_tag"])')
      ${pkgs.curl}/bin/curl -sL \
        "https://extensions.gnome.org/download-extension/$EXT_ID.shell-extension.zip?version_tag=$VERSION_TAG" \
        -o "$TMP/ext.zip"
      /usr/bin/gnome-extensions install --force "$TMP/ext.zip"
      rm -rf "$TMP"
    fi
  '';

  dconf.settings = {
    "org/gnome/shell/extensions/nightthemeswitcher/time" = {
      manual-schedule = true;
      sunrise = 7.0;
      sunset = 21.0;
      fullscreen-transition = true;
      nightthemeswitcher-ondemand-keybinding = [ "<Shift><Super>t" ];
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
