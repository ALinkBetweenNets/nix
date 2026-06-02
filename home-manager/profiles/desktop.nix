{
  lib,
  pkgs,
  flake-self,
  config,
  system-config,
  ...
}:
with lib;
{
  imports = [
    ../colorscheme.nix
    ./common.nix
    flake-self.homeModules.xdg
  ];
  config = {
    dconf = {
      enable = true;
      settings = {
        "org/maliit/keyboard/maliit" = {
          enabled-languages = [
            "en"
            "de"
            "emoji"
          ];
          theme = "BreezeDark";
        };
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      };
    };
    programs = {
      wezterm = {
        enable = true;
        enableZshIntegration = true;
        extraConfig = ''
          return {
            font = wezterm.font("FiraCode Nerd Font"),
            hide_tab_bar_if_only_one_tab = true,
          }
        '';
        #     window_background_opacity=0.7,
        #     text_background_opacity=0.3,
        # colorSchemes={
        #   them={
        #     background
        #   };
        # };
      };
      # kitty = {
      #   enable = false;
      #   enableGitIntegration = true;
      #   environment = {"LS_COLORS" = "1";};
      #   shellIntegration.enableZshIntegration=true;
      #   font = {
      #     name="FiraCode Nerd Font";
      #   };
      #   keybindings ={
      #     # "ctrl+shift+f"="SplitVertical={domain=\"CurrentPaneDomain\"}";
      #     # "ctrl+shift+n"="SplitHorizontal={domain=\"CurrentPaneDomain\"}";
      #     "ctrl+shift+n"="new_os_window";
      #     "ctrl+shift+enter"="new_window";
      #     "ctrl+shift+x"="close_window";
      #     "ctrl+shift+r"="start_resizing_window";
      #     "ctrl+tab"="next_tab";
      #     "ctrl+shift+tab"="previous_tab";
      #     "ctrl+alt+shift+right"="next_tab";
      #     "ctrl+alt+shift+left"="previous_tab";
      #     "ctrl+shift+left"="previous_window";
      #     "ctrl+shift+right"="next_window";
      #     "ctrl+shift+space"="focus_visible_window";
      #     "ctrl+alt+shift+down"="move_window_forward";
      #     "ctrl+alt+shift+up"="move_window_backward";
      #     "ctrl+alt+shift+f"="toggle_layout stack";
      #     # ctrl shift a 1 -> disable background transparency
      #     # ctrl shift a d -> reset background transparency to default
      #   };
      #   settings = {
      #     # themeFile = "LiquidCarbonTransparent";
      #     background_opacity = 0.7;
      #     dynamic_background_opacity = "yes";
      #     transparent_background_colors = "#000000@1";
      #     scrollback_lines=10000;
      #     enable_audio_bell=true;
      #     scrollback_pager_history_size=10;
      #     notify_on_cmd_finish ="invisible 10";
      #     # hide_window_decorations="yes";
      #     tab_bar_style="powerline";
      #     tab_bar_edge="bottom";
      #     ttab_powerline_style = "slanted";
      #     # tab_powerline_style="round";
      #     cursor_trail=100;
      #     cursor_trail_decay = "0.1 0.2";
      #     cursor_trail_start_threshold = 4;
      #     # window_margin_width=1;
      #     # window_border_width =    "1pt";
      #     active_border_color=     "#44ffff";
      #     single_window_margin=0;
      #     enabled_layouts="grid,tall,fat,vertical,horizontal,splits,stack";
      #
      #   };
      #
      # };
      firefox = {
        enable = true;
        configPath = ".mozilla/firefox";
      };
      yt-dlp = {
        enable = true;
        extraConfig = "--no-update";
        settings = {
          embed-thumbnail = true;
        };
      };
      mpv = {
        # package = pkgs.mpv-unwrapped.wrapper {
        #   mpv = pkgs.mpv-unwrapped.override { vapoursynthSupport = true; };
        #   youtubeSupport = true;
        # };
        enable = true;
        scripts = with pkgs.mpvScripts; [
          # uosc
          dynamic-crop
          eisa01.smartskip
          manga-reader
          mpris
          mpv-cheatsheet-ng
          mpv-image-viewer.image-positioning
          mpv-image-viewer.ruler
          mpv-notify-send
          mpv-osc-tethys
          mpv-playlistmanager
          mpv-webm
          occivink.seekTo
          quality-menu
          skipsilence
          sponsorblock
          thumbfast
          visualizer
          webtorrent-mpv-hook
          youtube-upnext
        ];
        bindings = {
          WHEEL_UP = "seek 10";
          WHEEL_DOWN = "seek -10";
          "Alt+0" = "set window-scale 0.5";
          "CTRL+1" =
            ''no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A (HQ)"'';
          "CTRL+2" =
            ''no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B (HQ)"'';
          "CTRL+3" =
            ''no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C (HQ)"'';
          "CTRL+4" =
            ''no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_Restore_CNN_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A+A (HQ)"'';
          "CTRL+5" =
            ''no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B+B (HQ)"'';
          "CTRL+6" =
            ''no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Restore_CNN_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C+A (HQ)"'';
          "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "GLSL shaders cleared"'';
        };
        config = {
          profile = "gpu-hq";
          # profiles = { fast = { vo = "vdpau"; }; };
          force-window = true;
          ytdl-format = "bestvideo+bestaudio";
          cache-default = 4000000;
          scriptOpts = "ytdl_hook-ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp";
          # Optimized shaders for higher-end GPU: Mode A (HQ)
          glsl-shaders = "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl";
        };
        defaultProfiles = [ "gpu-hq" ];
        extraInput = ''
          esc         quit                        #! Quit
          #           script-binding uosc/video   #! Video tracks
          # additional comments
        '';
      };
      #terminator.enable = true; # I prefer konsole
    };
    manual.html.enable = true;
    # Packages to install on all desktop systems
    home.packages =
      with pkgs;
      [
        neovide # neovim frontend
        ## Basics
        nfs-utils
        ## Spelling
        aspell
        hunspell
        hunspellDicts.de_DE
        hunspellDicts.en_US
        quodlibet-full
        ## Audio
        #helvum # Patchbay
        pavucontrol
        ## Multimedia
        vlc
        cobang # qr codes
        ## Encryption
        deno # for yt-dlp
        #veracrypt
        kdePackages.kleopatra # gpg/ pgp
        ## Misc
        xdg-utils
        scrcpy # ADB screenshare
        ktailctl # Tailscale GUI
        ## Editor
        kdePackages.kate # kate
        kdiff3
        obsidian
        ## Hex Editor
        hexdino # terminal vimlike hex editor
        okteta # hex editor
        imhex # broken
        ## File Sync
        #syncthing-tray
        ## Browser
        # librewolf
        # vivaldi # nice but proprietary
        # floorp # firefox fork, seems promising, needs more research
        #mullvad-vpn # is defined as program
        ## RDP
        remmina # VNC Client
        ## KDE Utils
        kdePackages.krfb # kde connect virtual monitor
        kdePackages.plasma-browser-integration
        kdePackages.qtwebsockets
        kdePackages.calendarsupport
        kdePackages.konsole
        # kdePackages.yakuake
        kdePackages.plasma-vault
        kdePackages.plasma-disks
        kdePackages.kfind
        kdePackages.colord-kde
        flake-self.inputs.zen-browser.packages.${system}.default
        # (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
      ]
      ++ lib.optionals (system-config.nixpkgs.hostPlatform.system == "x86_64-linux") [
        # bitwarden-desktop
        tor-browser
        mullvad-browser
      ];
  };
}
