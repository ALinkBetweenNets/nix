{ lib, pkgs, config, ... }:
with lib;
let cfg = config.link.plasma;
in {
  options.link.plasma.enable = mkEnableOption "enable plasma";
  config = mkIf cfg.enable {
    # home.packages = with pkgs; [ iosevka ];
    programs.plasma = {
      enable = true;
      configFile = {
        "dolphinrc"."DetailsMode"."PreviewSize" = 22;
        "dolphinrc"."DetailsMode"."SidePadding" = 0;
        "dolphinrc"."General"."LockPanels" = false;
        "dolphinrc"."General"."RememberOpenedTabs" = false;
        "dolphinrc"."General"."ViewPropsTimestamp" = "2024,7,3,11,31,59.911";
        "dolphinrc"."IconsMode"."PreviewSize" = 192;
        "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = true;
        "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 16;
        "dolphinrc"."PlacesPanel"."IconSize" = "-1";
        "dolphinrc"."PreviewSettings"."Plugins" =
          "appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,directorythumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,opendocumentthumbnail,svgthumbnail,windowsexethumbnail,windowsimagethumbnail,fontthumbnail,blenderthumbnail,ffmpegthumbs,gsthumbnail,mobithumbnail,rawthumbnail";
        "kcminputrc"."Libinput/1386/21125/Wacom HID 5285 Finger"."OutputName" =
          "eDP-1";
        "kcminputrc"."Libinput/1386/21125/Wacom HID 5285 Pen"."OutputName" =
          "eDP-1";
        "kcminputrc"."Libinput/1739/52828/SYNA800B:00 06CB:CE5C Touchpad"."NaturalScroll" =
          true;
        "kcminputrc"."Libinput/1739/52828/SYNA800B:00 06CB:CE5C Touchpad"."PointerAcceleration" =
          0.2;
        # "ksmserver"."Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
        # "ksmserver"."Lock Session" = [ "Meta+L" "Screensaver,Meta+L" "Screensaver,Lock Session" ];
        # "ksmserver"."Log Out" = "Ctrl+Alt+Del";
        # "ksmserver"."LogOut" = "none,,Log Out";
        # "ksmserver"."Reboot" = "none,,Reboot";
        # "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
        # "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
        # "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
        # "org_kde_powerdevil"."Hibernate" = "Hibernate";

        # "ksmserver"."Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
        "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
        "kded5rc"."Module-device_automounter"."autoload" = false;
        "kdeglobals"."KDE"."AnimationDurationFactor" = 0.5;
        "kdeglobals"."KFileDialog Settings"."Allow Expansion" = false;
        "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" =
          true;
        "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = true;
        "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
        "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
        "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
        "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
        "kdeglobals"."KFileDialog Settings"."Show Full Path" = false;
        "kdeglobals"."KFileDialog Settings"."Show hidden files" = false;
        "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = true;
        "kdeglobals"."KFileDialog Settings"."Show Preview" = true;
        "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
        "kdeglobals"."KFileDialog Settings"."Sort by" = "Date";
        "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
        "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
        "kdeglobals"."KFileDialog Settings"."Sort reversed" = true;
        "kdeglobals"."KFileDialog Settings"."Speedbar Width" = 140;
        "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
        "kdeglobals"."PreviewSettings"."MaximumRemoteSize" = 0;
        "kdeglobals"."WM"."activeBackground" = "49,54,59";
        "kdeglobals"."WM"."activeBlend" = "252,252,252";
        "kdeglobals"."WM"."activeForeground" = "252,252,252";
        "kdeglobals"."WM"."inactiveBackground" = "42,46,50";
        "kdeglobals"."WM"."inactiveBlend" = "161,169,177";
        "kdeglobals"."WM"."inactiveForeground" = "161,169,177";
        "kiorc"."Confirmations"."ConfirmDelete" = true;
        "kiorc"."Confirmations"."ConfirmEmptyTrash" = true;
        "kiorc"."Confirmations"."ConfirmTrash" = false;
        "kiorc"."Executable scripts"."behaviourOnLaunch" = "alwaysAsk";
        "klipperrc"."General"."IgnoreImages" = false;
        "klipperrc"."General"."MaxClipItems" = 30;
        "kservicemenurc"."Show"."compressfileitemaction" = true;
        "kservicemenurc"."Show"."extractfileitemaction" = true;
        "kservicemenurc"."Show"."forgetfileitemaction" = true;
        "kservicemenurc"."Show"."installFont" = true;
        "kservicemenurc"."Show"."kactivitymanagerd_fileitem_linking_plugin" =
          true;
        "kservicemenurc"."Show"."kdeconnectfileitemaction" = true;
        "kservicemenurc"."Show"."kdiff3fileitemaction" = true;
        "kservicemenurc"."Show"."kio-admin" = true;
        "kservicemenurc"."Show"."kleodecryptverifyfiles" = true;
        "kservicemenurc"."Show"."kleoencryptfiles" = true;
        "kservicemenurc"."Show"."kleoencryptfolder" = true;
        "kservicemenurc"."Show"."kleoencryptsignfiles" = true;
        "kservicemenurc"."Show"."kleosignencryptfolder" = true;
        "kservicemenurc"."Show"."kleosignfilescms" = true;
        "kservicemenurc"."Show"."kleosignfilesopenpgp" = true;
        "kservicemenurc"."Show"."makefileactions" = true;
        "kservicemenurc"."Show"."mountisoaction" = true;
        "kservicemenurc"."Show"."nextclouddolphinactionplugin" = true;
        "kservicemenurc"."Show"."plasmavaultfileitemaction" = true;
        "kservicemenurc"."Show"."runInKonsole" = true;
        "kservicemenurc"."Show"."setAsWallpaper" = true;
        "kservicemenurc"."Show"."sharefileitemaction" = true;
        "kservicemenurc"."Show"."slideshowfileitemaction" = true;
        "kservicemenurc"."Show"."tagsfileitemaction" = true;
        "kservicemenurc"."Show"."wallpaperfileitemaction" = true;
        # Perf: don't relaunch every previously-open app on login. "restoreSavedSession"
        # made "password entered -> usable taskbar" slow because Plasma re-spawned the
        # whole last session during startup. Empty session = desktop is ready immediately.
        "ksmserverrc"."General"."loginMode" = "emptySession";
        # Perf: Baloo had indexed ~2M files (6.6 GiB index); the file indexer churned
        # disk/CPU and made plasmashell (which draws the Meta launcher) laggy. Disable
        # file indexing entirely. Trade-off: no KRunner/Dolphin filename/content search.
        # (Existing index purged once with `balooctl6 disable`.)
        "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
        # Perf: the animated splash ("beautifultreeanimationp6") has a minimum display
        # time that delayed the desktop appearing. None = no splash, desktop shows sooner.
        "ksplashrc"."KSplash"."Theme" = "None";
        "ksplashrc"."KSplash"."Engine" = "none";
        "kwinrc"."Desktops"."Id_1" = "6268f093-e850-4a30-a436-befc9272e3d8";
        "kwinrc"."Desktops"."Id_2" = "4094dafc-06e8-411b-b328-0041d7dd28fd";
        "kwinrc"."Desktops"."Id_3" = "01671e7a-3d07-41ee-b059-2694a0488ec8";
        "kwinrc"."Desktops"."Id_4" = "6be2c4be-53d8-409d-825d-347c1f3bfd48";
        "kwinrc"."Desktops"."Id_5" = "90349340-f116-45d8-ba8d-149b4c4c6f6a";
        "kwinrc"."Desktops"."Number" = 5;
        "kwinrc"."NightColor"."Active" = true;
        "kwinrc"."NightColor"."LatitudeFixed" = 52.03;
        "kwinrc"."NightColor"."LongitudeFixed" = 8.53;
        "kwinrc"."NightColor"."Mode" = "Location";
        "kwinrc"."NightColor"."NightTemperature" = 2600;
        "kwinrc"."NightColor"."TransitionTime" = 180;
        "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "MNH";
        "kwinrc"."org.kde.kdecoration2"."ButtonsOnRight" = "SLBFIAX";
        # Perf: blur + background-contrast make the compositor repaint the region behind
        # translucent surfaces (Kickoff menu, panels) every frame, adding latency to the
        # Meta launcher appearing. Off = flatter look, snappier menus, less GPU work.
        "kwinrc"."Plugins"."blurEnabled" = false;
        "kwinrc"."Plugins"."contrastEnabled" = false;
        "kwinrc"."Plugins"."desktopchangeosdEnabled" = true;
        "kwinrc"."Plugins"."dimscreenEnabled" = true;
        "kwinrc"."Plugins"."fadedesktopEnabled" = true;
        "kwinrc"."Plugins"."slideEnabled" = false;
        "kwinrc"."Windows"."BorderSnapZone" = 100;
        "kwinrc"."Windows"."ElectricBorders" = 1;
        "kwinrc"."Windows"."Placement" = "Smart";
        "kwinrc"."Windows"."RollOverDesktops" = true;
        "kwinrc"."Windows"."WindowSnapZone" = 50;
        "kwinrc"."Xwayland"."Scale" = 1;
      };
      kwin = {
        # effects.shakeCursor.enable = true;
        effects.desktopSwitching.animation = "fade";
        virtualDesktops = {
          rows = 1;
          number = 5;
        };
      };
      workspace.lookAndFeel = "org.kde.breezedark.desktop";
      hotkeys.commands."launch-konsole" = {
        name = "Launch Konsole";
        key = "Meta+Alt+K";
        command = "konsole";
      };
      panels = [{
        location = "bottom";
        widgets = [
          # We can configure the widgets by adding the name and config
          # attributes. For example to add the the kickoff widget and set the
          # icon to "nix-snowflake-white" use the below configuration. This will
          # add the "icon" key to the "General" group for the widget in
          # ~/.config/plasma-org.kde.plasma.desktop-appletsrc.

          {
            name = "org.kde.plasma.kickoff";
            config = { General.icon = "nix-snowflake-white"; };
          }
          # Adding configuration to the widgets can also for example be used to
          # pin apps to the task-manager, which this example illustrates by
          # pinning dolphin and konsole to the task-manager by default.
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General.launchers = [
                "applications:org.kde.konsole.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:obsidian.desktop"
                "applications:zen.desktop"
                "applications:signal-desktop.desktop"
                "applications:org.telegram.desktop.desktop"
                "applications:virt-manager.desktop"
              ];
            };
          }
          # If no configuration is needed, specifying only the name of the
          # widget will add them with the default configuration.
          "org.kde.plasma.marginsseparator"
          # If you need configuration for your widget, instead of specifying the
          # the keys and values directly using the config attribute as shown
          # above, plasma-manager also provides some higher-level interfaces for
          # configuring the widgets. See modules/widgets for supported widgets
          # and options for these widgets. The widgets below shows two examples
          # of usage, one where we add a digital clock, setting 12h time and
          # first day of the week to sunday and another adding a systray with
          # some modifications in which entries to show.
          { digitalClock = { }; }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.appmenu"
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              # We explicitly show bluetooth and battery
              shown = [
                "org.kde.plasma.battery"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
              ];
              hidden = [ ];
            };
          }
        ];
      }];
    };
  };
}
