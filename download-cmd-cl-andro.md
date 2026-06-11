# Cl-Andro — Package Installation Guide

## Quick Start

```bash
# 1. Update package list
apt update

# 2. Install packages
apt install git                    # Version control
apt install vim                    # Text editor
apt install tmux                   # Terminal multiplexer
apt install htop                   # Process monitor
apt install jq                     # JSON processor
apt install wget                   # Download tool
apt install make                   # Build system
apt install rsync                  # File sync
apt install openssh                # SSH client
apt install perl                   # Scripting
apt install python                 # Python 3
apt install nodejs                 # Node.js + npm
apt install proot                  # Linux distro container
apt install proot-distro           # Distro manager
```

## Install Multiple at Once

```bash
apt install git vim tmux htop jq wget make rsync openssh perl
```

## Search for Packages

```bash
apt search <keyword>
apt search python     # Find all python-related packages
apt search lib        # Find all library packages
```

## View Package Info

```bash
apt show <package>
apt show git          # Details about the git package
```

## Update All Packages

```bash
apt update && apt upgrade
```

## Remove a Package

```bash
apt remove <package>
apt autoremove          # Clean unused dependencies
```

## Notes

- All packages are built for **aarch64 (arm64)** devices.
- Packages are signed with the cl-andro GPG key — verified automatically by apt.
- The repository URL is baked into the bootstrap APK; no manual `sources.list` editing needed.
