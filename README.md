# Devuan Live ISO Builder

This repository builds a Devuan Live ISO using live-build on GitHub Actions.

<img width="767" height="439" alt="image" src="https://github.com/user-attachments/assets/257c832d-079f-454b-926f-e0e625830450" />

## Features

- Based on Devuan Daedalus (Devuan 5)
- Uses sysvinit instead of systemd
- Includes XFCE desktop environment
- Auto-configured with live-boot
- Built with GitHub Actions CI/CD

## Quick Start

### Validate Configuration

To verify that the configuration is correct and ready to build:

```bash
./validate.sh
```

### Build ISO

To build the ISO locally:

```bash
sudo ./build.sh
```

The resulting ISO will be in the current directory.

## Configuration

The configuration is stored in the `config/` directory:
- `config/bootstrap` - Bootstrap configuration (Devuan mirrors, distribution)
- `config/common` - Common build settings
- `config/chroot` - Chroot stage settings
- `config/binary` - Binary/ISO stage settings (includes boot parameters)
- `config/package-lists/` - Package lists to install
- `config/hooks/` - Custom scripts to run during build

## GitHub Actions Build

The workflow automatically builds the ISO when changes are pushed to this repository. The build process:
1. Sets up a Debian container with privileged access
2. Installs build dependencies (live-build, debootstrap)
3. Sets up Devuan-specific debootstrap scripts
4. Installs Devuan keyring for package verification
5. Runs `lb build` to create the ISO
6. Uploads the resulting ISO as a release artifact

> [!NOTE]
> GitHub Actions workflows require approval for first-time runs in new repositories.
> Once approved by a repository administrator, subsequent runs will execute automatically.

## Included Software

The Live ISO includes:
- XFCE desktop environment with common utilities
- Firefox ESR web browser
- Network Manager for easy network configuration
- Graphics drivers for Intel, AMD, and common hardware
- Plymouth boot splash
- Standard system utilities
- Internet connection to download packages

## References

- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html)
- [Devuan](https://devuan.org/)
- [Devuan Packages](http://pkgmaster.devuan.org/)
