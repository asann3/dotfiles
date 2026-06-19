{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      userConfig = import ./user.nix;
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
          ];
          environment.shells = [ pkgs.fish ];

          # Necessary for using flakes on this system.
          # nix.settings.experimental-features = "nix-command flakes";
          nix.enable = false;

          # Enable alternative shell support in nix-darwin.
          programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          system.primaryUser = "${userConfig.user}";
          system.defaults = {
            # Trackpad
            trackpad = {
              Clicking = true; # Applied correctly, ignored by System Settings UI (macOS 15)
              ActuationStrength = 0;
            };
            # Dock
            dock = {
              autohide = true;
              show-recents = false;
              expose-group-apps = true;
            };
            # Finder
            finder = {
              AppleShowAllExtensions = true; # Applied correctly, ignored by System Settings UI (macOS 15)
              AppleShowAllFiles = true; # Requires `killall Finder` to take effect
              ShowPathbar = true;
              FXRemoveOldTrashItems = true;
              NewWindowTarget = "Home";
            };
            # User dictionary
            NSGlobalDomain = {
              NSAutomaticCapitalizationEnabled = false;
              NSAutomaticDashSubstitutionEnabled = false;
              NSAutomaticSpellingCorrectionEnabled = false;
              NSAutomaticQuoteSubstitutionEnabled = false;
              NSAutomaticPeriodSubstitutionEnabled = false;
            };
            # ScreenSaver
            screensaver = {
              askForPassword = true;
              askForPasswordDelay = 0;
            };
            # ControlCenter
            controlcenter.BatteryShowPercentage = true;
          };

          system.startup.chime = false;

          system.defaults.CustomUserPreferences = {
            "com.apple.systemsound" = {
              "com.apple.sound.uiaudio.enabled" = 0;
            };
            "com.apple.PowerChime" = {
              "ChimeOnAllHardware" = false;
              "ChimeOnNoHardware" = true;
            };
            NSGlobalDomain = {
              "com.apple.sound.beep.volume" = 0.0;
              "com.apple.sound.beep.feedback" = 0.0;
            };
            # Japanese input (Kotoeri): enable Windows-style key operation
            "com.apple.inputmethod.Kotoeri" = {
              JIMPrefWindowsModeKey = 1;
            };
            # Amethyst: resize windows using mouse
            "com.amethyst.Amethyst" = {
              "mouse-resizes-windows" = 1;
            };
          };

          networking.applicationFirewall.enable = true;

          security.pam.services.sudo_local.touchIdAuth = true;

          launchd.user.agents."com.apple.rcd" = {
            serviceConfig.Disabled = true;
          };

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
          users.users."${userConfig.user}" = {
            name = "${userConfig.user}";
            home = "/Users/${userConfig.user}";
            shell = pkgs.fish;
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#${userConfig.host}
      darwinConfigurations."${userConfig.host}" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit userConfig; };
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${userConfig.user}" = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit userConfig; };
          }
        ];
      };
    };
}
