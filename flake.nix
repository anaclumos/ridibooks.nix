{
  description = "A Nix flake for Ridibooks";
  inputs = {
    ridibooks-exe = {
      url = "https://viewer-ota.ridicdn.net/pc_electron/Ridibooks%20Setup%200.11.6.exe";
      flake = false;
    };
    ridibooks-icon = {
      url = "https://ridicorp.com/wp-content/uploads/2025/07/%EB%A6%AC%EB%94%94.png";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ridibooks-exe, ridibooks-icon }: {
    packages.x86_64-linux =
      let pkgs = import "${nixpkgs}" { system = "x86_64-linux"; };

      in with pkgs; {
        default = self.packages.x86_64-linux.ridibooks;
        ridibooks = let
          desktopItem = makeDesktopItem {
            name = "ridibooks";
            exec = "ridibooks %U";
            icon = "ridibooks";
            desktopName = "Ridibooks";
            genericName = "E-Book Reader";
            comment = "E-book reader and digital bookstore";
            categories = [ "Office" "Viewer" ];
            mimeTypes = [ "x-scheme-handler/ridibooks" ];
            startupWMClass = "ridibooks.exe";
          };
        in stdenv.mkDerivation rec {
          pname = "ridibooks";
          version = "0.11.6";
          src = ridibooks-exe;
          dontUnpack = true;

          nativeBuildInputs = [ makeWrapper wineWowPackages.stable winetricks ];

          buildInputs = [
            pretendard
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
          ];

          installPhase = ''
            mkdir -p $out/bin $out/share/icons/hicolor/scalable/apps $out/share/applications $out/share/ridibooks
            cp ${ridibooks-icon} $out/share/icons/hicolor/scalable/apps/ridibooks.png
            cp ${src} $out/share/ridibooks/Ridibooks_Setup.exe
            cat > $out/bin/ridibooks <<EOF
            #!/usr/bin/env bash

            export GTK_IM_MODULE=fcitx
            export QT_IM_MODULE=fcitx
            export XMODIFIERS=@im=fcitx

            PREFIX="\''${XDG_DATA_HOME:-\$HOME/.local/share}/ridibooks"

            INSTALLER="$out/share/ridibooks/Ridibooks_Setup.exe"

            WINE_BIN="${wineWowPackages.stable}/bin/wine"
            WINEBOOT_BIN="${wineWowPackages.stable}/bin/wineboot"
            if [ ! -d "\$PREFIX" ]; then
              mkdir -p "\$PREFIX"
              WINEPREFIX="\$PREFIX" "\$WINEBOOT_BIN" -u
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Control Panel\\Desktop" /v "LogPixels" /t REG_DWORD /d 96 /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "DPI" /t REG_SZ /d "96" /f
              WINEPREFIX="\$PREFIX" "\$WINEBOOT_BIN" -u
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Control Panel\\International" /v "Locale" /t REG_SZ /d "00000412" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Nls\\Language" /v "Default" /t REG_SZ /d "0412" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Nls\\Language" /v "InstallLanguage" /t REG_SZ /d "0412" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "Decorated" /t REG_SZ /d "Y" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "Managed"   /t REG_SZ /d "Y" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "UseTakeFocus" /t REG_SZ /d "N" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg delete "HKEY_CURRENT_USER\\Software\\Wine\\Explorer" /v "Desktop" /f 2>/dev/null || true
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\Drivers" /v "Audio" /t REG_SZ /d "" /f
              # Enable clipboard integration
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "UseXIM" /t REG_SZ /d "Y" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "UsePrimarySelection" /t REG_SZ /d "N" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "GrabClipboard" /t REG_SZ /d "Y" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v "UseSystemClipboard" /t REG_SZ /d "Y" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\DragAcceptFiles" /v "Accept" /t REG_DWORD /d 1 /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\OleDropTarget" /v "Enable" /t REG_DWORD /d 1 /f
            fi
            if [ ! -f "\$PREFIX/.winetricks_done" ]; then
              WINEPREFIX="\$PREFIX" ${winetricks}/bin/winetricks corefonts -q
              touch "\$PREFIX/.winetricks_done"
            fi
            # Configure font substitutions for emoji support
            if [ ! -f "\$PREFIX/.fonts_configured" ]; then
              echo "Configuring font replacements..."
              
              # Replace only specific Western fonts with Pretendard
              # This preserves Korean fonts while updating UI fonts
              for font in "Arial" "Times New Roman" "Courier New" "Verdana" "Tahoma" \
                         "Georgia" "Trebuchet MS" "Comic Sans MS" "Impact" \
                         "Lucida Console" "Lucida Sans Unicode" "Palatino Linotype" \
                         "Segoe UI" "Segoe Print" "Segoe Script" \
                         "Calibri" "Cambria" "Candara" "Consolas" "Constantia" "Corbel"; do
                WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\Fonts\\Replacements" /v "\$font" /t REG_SZ /d "Pretendard" /f
              done
              
              # Ensure Korean fonts use Pretendard which has excellent Korean support
              for font in "Gulim" "Dotum" "Batang" "Gungsuh" "Malgun Gothic"; do
                WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\Fonts\\Replacements" /v "\$font" /t REG_SZ /d "Pretendard" /f
              done
              
              # Map emoji/symbol fonts to Noto Color Emoji
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\Fonts\\Replacements" /v "Segoe UI Emoji" /t REG_SZ /d "Noto Color Emoji" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\Fonts\\Replacements" /v "Segoe UI Symbol" /t REG_SZ /d "Noto Color Emoji" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Software\\Wine\\Fonts\\Replacements" /v "Apple Color Emoji" /t REG_SZ /d "Noto Color Emoji" /f
              
              # Set up font linking for emoji support - Pretendard cascades to Noto Color Emoji
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\FontLink\\SystemLink" /v "Pretendard" /t REG_MULTI_SZ /d "Noto Color Emoji,NotoColorEmoji.ttf" /f
              
              # Enable font smoothing
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Control Panel\\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Control Panel\\Desktop" /v "FontSmoothingType" /t REG_DWORD /d 2 /f
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" reg add "HKEY_CURRENT_USER\\Control Panel\\Desktop" /v "FontSmoothingGamma" /t REG_DWORD /d 1400 /f
              
              # Link system fonts to Wine prefix
              mkdir -p "\$PREFIX/drive_c/windows/Fonts"
              # Link Pretendard fonts first
              for font in ${pretendard}/share/fonts/opentype/*.otf ${pretendard}/share/fonts/truetype/*.ttf; do
                if [ -f "\$font" ]; then
                  ln -sf "\$font" "\$PREFIX/drive_c/windows/Fonts/" 2>/dev/null || true
                fi
              done
              # Then link Noto fonts for emoji support
              for font in ${noto-fonts}/share/fonts/truetype/*.ttf ${noto-fonts-cjk-sans}/share/fonts/opentype/*/*.otf ${noto-fonts-color-emoji}/share/fonts/truetype/*.ttf; do
                if [ -f "\$font" ]; then
                  ln -sf "\$font" "\$PREFIX/drive_c/windows/Fonts/" 2>/dev/null || true
                fi
              done
              
              touch "\$PREFIX/.fonts_configured"
            fi
            if [ ! -f "\$PREFIX/drive_c/Program Files (x86)/RIDI/RIDI.exe" ] && [ ! -f "\$PREFIX/drive_c/Program Files/RIDI/RIDI.exe" ]; then
              echo "Installing Ridibooks..."
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" "\$INSTALLER"
            fi

            # Remove the installer-created desktop entries to avoid duplicates
            rm -f "\$HOME/.local/share/applications/wine/Programs/RIDI.desktop" 2>/dev/null
            rm -f "\$HOME/.local/share/applications/wine/Programs/리디북스.desktop" 2>/dev/null

            # Try to find and run the installed executable
            if [ -f "\$PREFIX/drive_c/Program Files (x86)/RIDI/RIDI.exe" ]; then
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" "C:\\Program Files (x86)\\RIDI\\RIDI.exe" "\$@"
            elif [ -f "\$PREFIX/drive_c/Program Files/RIDI/RIDI.exe" ]; then
              WINEPREFIX="\$PREFIX" "\$WINE_BIN" "C:\\Program Files\\RIDI\\RIDI.exe" "\$@"
            else
              echo "Ridibooks executable not found. Please check the installation."
              exit 1
            fi
            EOF
            chmod +x $out/bin/ridibooks

            # Copy the desktop entry from makeDesktopItem
            cp -r ${desktopItem}/share/applications $out/share/
          '';
          meta = with lib; {
            description = "E-book reader and digital bookstore";
            homepage = "https://ridibooks.com";
            license = licenses.unfree;
            platforms = [ "x86_64-linux" ];
          };
        };
      };
    apps.x86_64-linux.ridibooks = {
      type = "app";
      program = "${self.packages.x86_64-linux.ridibooks}/bin/ridibooks";
    };
    apps.x86_64-linux.default = self.apps.x86_64-linux.ridibooks;
  };
}