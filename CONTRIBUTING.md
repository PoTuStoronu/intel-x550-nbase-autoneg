# Contributing

Contributions, compatibility reports, documentation improvements, and carefully reviewed fixes are welcome.

This project is **experimental and not sufficiently tested**. Please avoid describing any operating system, driver, firmware version, or adapter as "fully supported" unless reproducible testing evidence is available.

## Before submitting an issue

- Search existing issues for the same PCI ID, driver, or symptom.
- Use the hardware test template when reporting hardware results.
- Include OS, kernel, `ixgbe` driver, firmware, PCI IDs, the connected switch/peer, and whether the configuration persisted after reboot.
- State whether the test was conducted on actual hardware or only through static/syntax checks.
- Redact MAC addresses, device serial numbers, private infrastructure details, and IP addresses.

## Pull requests

1. Keep the shell script compatible with POSIX `/bin/sh` and OpenWrt BusyBox `ash` where possible.
2. Do not add new X550 PCI IDs without explaining the hardware variant and why it is safe to include.
3. Preserve the checks that prevent modifying unrelated network adapters.
4. Avoid surprising changes to default routes, bridges, IP addresses, or firewall settings.
5. Document any behavior that could disrupt connectivity.
6. Run `sh -n x550-nbase.sh` and, if available, `shellcheck x550-nbase.sh`.
7. Clearly distinguish **tested**, **partially tested**, and **untested** functionality.
8. Describe a practical recovery or rollback path for any change that affects startup behavior.

Do not post credentials or sensitive logs in issues or pull requests.
