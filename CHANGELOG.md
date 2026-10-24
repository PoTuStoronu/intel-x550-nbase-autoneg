# Changelog

This project follows a simple, human-readable changelog. Version numbers and release dates may be assigned when releases are published.

## Unreleased — experimental initial publication

### Added

- Automatic discovery of recognized Intel X550 copper network interfaces using PCI IDs and `ixgbe` driver verification.
- Checks for the five expected link speeds before applying a fixed advertisement mask.
- `status`, `apply`, `install`, and `uninstall` commands.
- Intended systemd/udev integration on Debian, Ubuntu, and Proxmox VE.
- Intended init/hotplug integration on OpenWrt-derived distributions.
- Repository documentation and hardware test reporting template.

### Known limitations

- **Insufficient testing on physical hardware and across intended distributions.**
- No automatic rollback and no saved original advertisement settings.
- Potential link negotiation failure or remote connectivity loss.
- OEM variant support and boot/hotplug persistence are not comprehensively verified.
