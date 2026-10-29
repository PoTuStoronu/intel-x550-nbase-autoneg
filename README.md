# Intel X550 NBASE-T Auto-Advertisement

A small, experimental POSIX shell script that finds supported **Intel X550 copper Ethernet interfaces** by their PCI identifiers and enables advertisement of **100 Mbps, 1 Gbps, 2.5 Gbps, 5 Gbps, and 10 Gbps** during link auto-negotiation.

No interface names need to be specified in advance. The script is intended for Debian, Ubuntu, Proxmox VE, and x86 OpenWrt-derived systems, including ImmortalWrt.

> [!CAUTION]
> **EXPERIMENTAL — NOT SUFFICIENTLY TESTED.** This project has **not undergone comprehensive testing on real X550 hardware or across the claimed operating systems**. Successful operation, compatibility, stability, and persistence after reboot **have not been established**. Enabling additional advertised speeds can interrupt connectivity and may expose known interoperability problems with certain switches. **Do not deploy on critical, unattended, or production network links without first testing locally and ensuring you have out-of-band or physical recovery access.** Use at your own risk.

## Why does this exist?

Some Intel X550 copper adapters support 2.5GBASE-T and 5GBASE-T but do not advertise those speeds by default under the Linux `ixgbe` driver. The conservative default helps avoid auto-negotiation problems with certain network devices. This script explicitly opts in to advertising the five speeds listed above.

**Enabling advertisement is not the same as forcing the link to 10 Gbps.** Actual link speed depends on the adapter, cable, switch or peer, firmware, and negotiation result.

For additional background, refer to the [Linux kernel's `ixgbe` documentation](https://docs.kernel.org/networking/device_drivers/ethernet/intel/ixgbe.html).

## What it does

- Enumerates `/sys/class/net/` to find network interfaces automatically.
- Selects only recognized Intel PCI device IDs with the `ixgbe` driver.
- Confirms that `ethtool` reports all five expected copper link modes.
- Skips interfaces already advertising all five modes with auto-negotiation enabled.
- Runs `ethtool -s <interface> autoneg on advertise 0x1800000001028` on eligible interfaces.
- Optionally installs boot-time and hotplug hooks for supported init environments.

## What it does **not** do

- It does not change interface names, IP addresses, VLANs, bridges, routes, firewall rules, or MTU settings.
- It does not upgrade drivers or network adapter firmware.
- It does not guarantee 2.5G/5G negotiation or cure interoperability problems.
- It does not manage Intel X710/X540 adapters or other Intel/Realtek/Marvell NICs.
- It does not make the configuration persistent by itself unless the `install` command is used.
- It does not provide an automatic rollback if connectivity is lost.
- It does not configure NICs passed through to a different guest OS; run it in the OS that owns the physical NIC.

## Intended platforms — validation status

| Platform | Intended installation method | Validation status |
| --- | --- | --- |
| Debian with systemd | systemd service + udev rule | **Not comprehensively tested** |
| Ubuntu with systemd | systemd service + udev rule | **Not comprehensively tested** |
| Proxmox VE (including 9.x) | systemd service + udev rule | **Initial functional test passed** |
| x86 OpenWrt / ImmortalWrt | init script + network hotplug hook | **Not comprehensively tested** |

Other distributions, system configurations, and network manager combinations are not covered by this project's stated scope. A compatibility claim in this document indicates an **intended target**, not a successful hardware test.

## Prerequisites

- Root privileges for `apply`, `install`, and `uninstall`.
- A Linux system with `/sys/class/net/` and the `ixgbe` driver.
- `ethtool` (the installer may attempt to install it using `apt-get`, `opkg`, or `apk`).
- A compatible Intel X550 copper PCI device recognized by this version of the script.
- **Console access or another independent management path** before changing a live link.

The current device-ID allowlist is `8086:1563`, `8086:15d1`, `8086:15ad`, and `8086:15c8`. Not every OEM adapter or X550 variant is necessarily included or supported.

## Download

To download with `curl` run the following command:

```sh
curl -fL --retry 3 \
  -o x550-nbase.sh \
  https://raw.githubusercontent.com/PoTuStoronu/intel-x550-nbase-autoneg/main/x550-nbase.sh
```

To download with `wget` run the following command:

```sh
wget -O x550-nbase.sh \
  https://raw.githubusercontent.com/PoTuStoronu/intel-x550-nbase-autoneg/main/x550-nbase.sh
```

## Installation

**Review the shell script before executing it as root.**

Inspect the detected adapters first (read-only):

```sh
sh ./x550-nbase.sh status
```

Install the persistent service and event hook:

```sh
sudo sh ./x550-nbase.sh install
```

On OpenWrt/ImmortalWrt, where `sudo` may not be available, run as `root`:

```sh
sh ./x550-nbase.sh install
```

The installation command copies the script to `/usr/local/sbin/x550-nbase.sh`, attempts to install `ethtool` if needed, and registers the platform-specific startup hooks. **It does not deliberately apply new link settings during installation.** The hooks can apply them on future system/network events, however; do not treat installation as risk-free on a remotely managed machine.

### Manually apply the settings

**Warning: this can renegotiate and temporarily disconnect the affected link.**

```sh
sudo sh /usr/local/sbin/x550-nbase.sh apply
```

Or, on OpenWrt as root:

```sh
sh /usr/local/sbin/x550-nbase.sh apply
```

Inspect the result:

```sh
sh /usr/local/sbin/x550-nbase.sh status
ethtool YOUR_X550_INTERFACE
```

Look for the five speeds under **Advertised link modes**, `Auto-negotiation: on`, and a plausible `Speed:` and `Link detected:` value. **A successful command exit does not by itself prove that link negotiation succeeded or that the connection is stable.**

## Commands

| Command | Purpose |
| --- | --- |
| `status` | Display detected adapters and selected link-mode information (no root required in typical setups). |
| `apply` | Attempt to advertise all five speeds on eligible X550 interfaces. |
| `install` | Copy the script and register boot/hotplug hooks; may install `ethtool`. |
| `uninstall` | Remove the installed script and hooks; does **not** immediately restore the previous link advertisement. |

Running without arguments currently defaults to `apply`. For safety, prefer providing an explicit command.

## Installed files

**Debian / Ubuntu / Proxmox VE**

```text
/usr/local/sbin/x550-nbase.sh
/etc/systemd/system/x550-nbase.service
/etc/udev/rules.d/80-x550-nbase.rules
```

**OpenWrt / ImmortalWrt**

```text
/usr/local/sbin/x550-nbase.sh
/etc/init.d/x550-nbase
/etc/hotplug.d/net/95-x550-nbase
```

Boot ordering, hotplug behavior, and compatibility with distribution-specific network configuration are **not yet verified across the intended platforms**.

## Restore / undo

Remove persistence hooks:

```sh
sudo sh /usr/local/sbin/x550-nbase.sh uninstall
```

On OpenWrt as root, omit `sudo`. **Uninstalling will not immediately reverse already-applied link settings.** After uninstalling, a driver reload or reboot will normally restore the driver's default advertisement behavior, but that recovery behavior is not guaranteed for every firmware, driver, or operating-system configuration. A reboot may also be disruptive.

If you are remotely connected through the affected NIC, **do not rely on this uninstall command as an automatic rescue procedure**.

## Troubleshooting

**No supported Intel X550 copper interfaces detected**

Confirm the physical adapter and driver using `lspci -nnk`, `ethtool -i <interface>`, and `/sys/class/net/<interface>/device/{vendor,device}`. The card may be absent, passed through to a VM, bound to another driver, or outside the current PCI ID allowlist.

**The NIC is found but skipped**

The driver does not report all five expected speeds. This may reflect a different controller revision, OEM configuration, firmware limitation, or the link-mode parsing assumptions in this experimental script. Do not bypass the safety check without understanding the hardware.

**Negotiation drops from 10G to 1G, or the link goes down**

The endpoint may have a problem negotiating when 2.5G/5G are advertised. Revert from a local console, verify the peer's supported modes, and consider a narrower advertisement set rather than assuming the issue is a cable fault.

**Settings disappear after reboot**

Check `systemctl status x550-nbase.service` and `journalctl -u x550-nbase.service -b` on systemd systems. On OpenWrt, inspect `/etc/init.d/x550-nbase` and `/etc/hotplug.d/net/95-x550-nbase` and verify that the hotplug event used by your system actually fires. This feature has not been comprehensively validated.

## Known limitations

- Only four PCI device IDs are recognized; the list is not exhaustive.
- The five speeds are explicitly fixed in the current script; they are not dynamically tailored to the attached switch.
- Changes may trigger link renegotiation and loss of remote access.
- The script does not save the prior advertisement mask for rollback.
- It assumes English-formatted `ethtool` output for parsing link modes.
- Some OEM firmware, driver revisions, and switching hardware may behave differently.
- Startup and hotplug integration have not been tested across all intended OS releases.
- Testing is insufficient to establish long-term stability or production readiness.

## Testing and issue reports

If you test this on real hardware, please open an issue using the [test report template](.github/ISSUE_TEMPLATE/hardware-test.yml). Include the OS and kernel versions, NIC PCI ID, driver and firmware versions, peer device model, actual negotiated speeds, and whether reboot persistence worked. Remove MAC addresses, serial numbers, public IP addresses, and other sensitive information before posting.

See [TESTING.md](docs/TESTING.md) for a suggested validation checklist, [SECURITY.md](SECURITY.md) for security reporting, and [CONTRIBUTING.md](CONTRIBUTING.md) for contributions.

## Disclaimer

This is an **unofficial, community-oriented experiment**, not an Intel-supported utility and not affiliated with or endorsed by Intel, Debian, Ubuntu, Proxmox, OpenWrt, or ImmortalWrt. **The authors and contributors make no warranty that it is safe, compatible, functional, or suitable for any particular environment.** See [DISCLAIMER.md](DISCLAIMER.md) and [LICENSE](LICENSE).
