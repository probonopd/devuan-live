# Devuan Live ISO Builder

> [!WARNING]  
> The ISOs generated in this repository are for testing and may contain known issues.

This repository builds a Devuan Live ISO using live-build, similar to the [gershwin-on-debian](https://github.com/gershwin-desktop/gershwin-on-debian) project but using Devuan instead of Debian.

## Features

- Based on Devuan Chimaera
- Uses sysvinit instead of systemd
- Includes XFCE desktop environment
- Auto-configured with live-boot
- Built with GitHub Actions CI/CD

## Building Locally

To build the ISO locally, you need to install `live-build` and run:

```bash
sudo lb config
sudo lb build
```

The resulting ISO will be in the current directory.

## Configuration

The configuration is stored in the `config/` directory:
- `config/bootstrap` - Bootstrap configuration (Devuan mirrors, distribution)
- `config/common` - Common build settings
- `config/chroot` - Chroot stage settings
- `config/binary` - Binary/ISO stage settings
- `config/package-lists/` - Package lists to install
- `config/hooks/` - Custom scripts to run during build
- `config/bootloaders/` - Bootloader configuration

## References

- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html)
- [Devuan](https://devuan.org/)