{
  description = "Ridibooks PC-viewer wrapped for Linux with Wine (x86_64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    ridibooks-exe = {
      url =
        "https://viewer-ota.ridicdn.net/pc_electron/Ridibooks%20Setup%200.11.6.exe";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ridibooks-exe }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      desktopItem = pkgs.makeDesktopItem {
        name = "ridibooks";
        exec = "ridibooks %U";
        desktopName = "Ridibooks";
        genericName = "E-book reader";
        categories = [ "Office" "Viewer" ];
        startupWMClass = "Ridibooks.exe";

        icon = "ridibooks";
      };
    in {

      packages.${system} = let
        ridibooks = pkgs.stdenv.mkDerivation rec {
          pname = "ridibooks";
          version = "0.11.6";
          src = ridibooks-exe;
          dontUnpack = true;

          nativeBuildInputs =
            [ pkgs.makeWrapper pkgs.wineWowPackages.stable pkgs.winetricks ];

          buildInputs = [
            pkgs.pretendard
            pkgs.noto-fonts
            pkgs.noto-fonts-cjk-sans
            pkgs.noto-fonts-color-emoji
          ];

          installPhase = ''
            mkdir -p $out/bin $out/share/${pname}
            cp ${src} $out/share/${pname}/Setup.exe




            cat > $out/bin/${pname} <<'EOF'
            #!/usr/bin/env bash
            set -euo pipefail

            export GTK_IM_MODULE=fcitx
            export QT_IM_MODULE=fcitx
            export XMODIFIERS=@im=fcitx

            PNAME="ridibooks"
            PREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/''${PNAME}"

            INSTALLER="$(dirname "$(readlink -f "$0")")/../share/''${PNAME}/Setup.exe"

            WINE="''${WINE:-wine}"
            WINEBOOT="''${WINEBOOT:-wineboot}"

            if [ ! -d "$PREFIX" ]; then
              mkdir -p "$PREFIX"
              WINEPREFIX="$PREFIX" "$WINEBOOT" -u
              WINEPREFIX="$PREFIX" "$WINE" reg add "HKEY_CURRENT_USER\\Control Panel\\Desktop" /v LogPixels /t REG_DWORD /d 96 /f
              WINEPREFIX="$PREFIX" "$WINE" reg add "HKEY_CURRENT_USER\\Software\\Wine\\X11 Driver" /v DPI /t REG_SZ /d 96 /f
              WINEPREFIX="$PREFIX" "$WINE" reg add "HKEY_CURRENT_USER\\Control Panel\\International" /v Locale /t REG_SZ /d 00000412 /f
              WINEPREFIX="$PREFIX" "$WINE" reg add "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Nls\\Language" /v Default /t REG_SZ /d 0412 /f
              WINEPREFIX="$PREFIX" "$WINE" reg add "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Nls\\Language" /v InstallLanguage /t REG_SZ /d 0412 /f
            fi

            if [ ! -f "$PREFIX/.winetricks_done" ]; then
              WINEPREFIX="$PREFIX" winetricks corefonts -q
              touch "$PREFIX/.winetricks_done"
            fi

            EXE86="$PREFIX/drive_c/Program Files (x86)/RIDI/Ridibooks/Ridibooks.exe"
            EXE64="$PREFIX/drive_c/Program Files/RIDI/Ridibooks/Ridibooks.exe"

            if [ ! -f "$EXE86" ] && [ ! -f "$EXE64" ]; then
              echo "Installing Ridibooks..."
              WINEPREFIX="$PREFIX" "$WINE" "$INSTALLER"
            fi

            rm -f "$HOME/.local/share/applications/wine/Programs/"*.desktop 2>/dev/null || true

            if [ -f "$EXE86" ]; then
              WINEPREFIX="$PREFIX" "$WINE" "$EXE86" "$@"
            else
              WINEPREFIX="$PREFIX" "$WINE" "$EXE64" "$@"
            fi
            EOF
            chmod +x $out/bin/${pname}




            cp -r ${desktopItem}/share/applications $out/share/
          '';

          meta = with pkgs.lib; {
            description = "E-book reader and digital bookstore";
            homepage = "https://ridibooks.com";
            license = licenses.unfree;
            platforms = [ system ];
          };
        };
      in {
        default = ridibooks;
        inherit ridibooks;
      };

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.ridibooks}/bin/ridibooks";
      };
    };
}
