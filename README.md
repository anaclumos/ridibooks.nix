# Ridibooks Nix Flake

A Nix flake for running Ridibooks on NixOS using Wine.

## Installation

```bash
nix run github:anaclumos/ridibooks.nix
```

Or add to your system configuration:

```nix
{
  inputs.ridibooks.url = "github:anaclumos/ridibooks.nix";
  
  # In your system packages
  environment.systemPackages = [
    inputs.ridibooks.packages.x86_64-linux.ridibooks
  ];
}
```

Then run `ridibooks` in your terminal. This will install and create Ridibooks desktop entry.

## Features

- Runs Ridibooks Windows application through Wine
- Includes Korean font support (Pretendard)
- Emoji support with Noto Color Emoji
- fcitx5 input method integration
- Desktop entry with proper icon

## Notes

- The application will be installed to `~/.local/share/ridibooks` on first run
- Wine prefix is configured with Korean locale settings
- Includes font replacements for better readability

## Uninstall

```
rm -rf ~/.local/share/applications/wine/Programs/Ridibooks.desktop
rm -rf ~/.local/share/ridibooks
```