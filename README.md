# Devuan Live ISO Builder

> [!WARNING]  
> The ISOs generated in this repository are for testing and may contain known issues.

This repository builds a Devuan Live ISO using live-build, similar to the [gershwin-on-debian](https://github.com/gershwin-desktop/gershwin-on-debian) project but using Devuan instead of Debian.

## Features

- Based on Devuan Chimaera (Devuan 4)
- Uses sysvinit instead of systemd
- Includes XFCE desktop environment
- Auto-configured with live-boot
- Built with GitHub Actions CI/CD

## Building Locally

To build the ISO locally, you need to install `live-build` and run:

```bash
# Install live-build
sudo apt-get install live-build debootstrap

# Create symlink for Devuan chimaera script
sudo ln -sf sid /usr/share/debootstrap/scripts/chimaera

# Install Devuan keyring (optional, for package verification)
wget http://pkgmaster.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2023.10.07_all.deb
sudo dpkg -i devuan-keyring_2023.10.07_all.deb

# Configure and build
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

## GitHub Actions Build

The workflow automatically builds the ISO when changes are pushed. The build process:
1. Sets up a Debian container with privileged access
2. Installs build dependencies (live-build, debootstrap)
3. Sets up Devuan-specific debootstrap scripts
4. Installs Devuan keyring for package verification
5. Runs `lb build` to create the ISO
6. Uploads the resulting ISO as a release artifact

## References

- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html)
- [Devuan](https://devuan.org/)
- [Devuan Packages](http://pkgmaster.devuan.org/)