# Hardware Validation Checklist

> This is a **proposed test plan**, not a claim that the script has passed these tests. The project has **not been sufficiently tested**.

## System and adapter information

Record the following, removing sensitive information before publishing:

```sh
uname -a
lspci -nnk | grep -A 5 -i ethernet
ip -br link
ethtool -i YOUR_X550_INTERFACE
ethtool YOUR_X550_INTERFACE
```

Record OEM adapter model, PCI vendor/device IDs, driver version, firmware/NVM version, connected switch or peer, and link cable type.

## Verification matrix

| Test | Expected result | Result |
| --- | --- | --- |
| `sh -n x550-nbase.sh` | No shell syntax errors | Not yet recorded |
| `status` before install | Displays recognized X550 interfaces only | Not yet recorded |
| Unrelated Intel/Realtek NIC present | Remains unchanged | Not yet recorded |
| `apply` on supported X550 | Advertises all five speeds | Not yet recorded |
| Run `apply` a second time | Skips already-correct interfaces | Not yet recorded |
| Connect to 1G peer | Negotiates the expected mode | Not yet recorded |
| Connect to 2.5G peer | Negotiates 2.5G when interoperable | Not yet recorded |
| Connect to 5G peer | Negotiates 5G when interoperable | Not yet recorded |
| Connect to 10G peer | Negotiates 10G when interoperable | Not yet recorded |
| Reboot after `install` | Settings return as intended | Not yet recorded |
| Network device re-add/hotplug | Configuration reapplied as intended | Not yet recorded |
| `uninstall` | Removes registered files and hooks | Not yet recorded |
| Driver reload/reboot after uninstall | Default settings restored as expected | Not yet recorded |

Test each intended OS and relevant hardware/firmware combination independently; one successful platform does not validate all others.

## Stability checks

During 2.5G/5G/10G tests, monitor link state, packet errors and drops, and application throughput. Repeat link negotiation and reboot tests. If using `iperf3`, record direction, parallel streams, duration, and the peer's capabilities. A brief successful throughput run is not proof of long-term stability.

## Important safety practices

Use local or independent management access. Do **not** first run the script on your only remotely accessible router or hypervisor uplink. Back up relevant network configuration and have a recovery plan before `apply` or `install`.
