# Experimental Software Disclaimer

> **IMPORTANT: NOT SUFFICIENTLY TESTED — USE AT YOUR OWN RISK.**

This repository contains an experimental script for changing advertised Ethernet link speeds on certain Intel X550 copper adapters.

## Validation status

- The script has **not been comprehensively tested on physical Intel X550 hardware**.
- The installation, startup, and hotplug workflows have **not been fully validated** across Debian, Ubuntu, Proxmox VE, OpenWrt, or ImmortalWrt.
- Compatibility with specific OEM adapters, drivers, firmware, switches, and cables **has not been established**.
- Long-term reliability, recovery from failures, and production suitability **have not been demonstrated**.
- A shell syntax check or successful installation **is not proof** that the script works correctly on real hardware.

## Risks

Running the script can change how network links negotiate. Possible outcomes include a lower link speed, brief or prolonged disconnection, loss of remote administration access, or an inability to establish a link with certain switches. Boot-time or hotplug automation can repeat the same problem after a reboot or reconnect.

The script runs as root when applying or installing settings and may also modify system startup configuration and install packages. Review the source code and maintain backups and a tested recovery path.

## Recommended precautions

1. First test on a noncritical link with physical console access.
2. Document the original `ethtool` link-mode output and driver/firmware information.
3. Test 1G, 2.5G, 5G, and 10G peers as applicable, including repeated link up/down cycles.
4. Verify connectivity, throughput, packet errors, and link stability under load.
5. Test startup persistence and uninstall/recovery before relying on the automation.

This is not an official Intel tool. No guarantee is provided that any reported issue can be resolved or that a particular adapter will work. Refer to [LICENSE](LICENSE) for the software's legal terms.
