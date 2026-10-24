# Security Policy

## Support status

**Experimental / not production-ready.** This project has not received a comprehensive security audit or sufficient real-world validation. No stable support or security-update SLA is offered.

## Reporting a vulnerability

Please avoid publishing working exploits, credentials, or sensitive system logs in a public issue. If the repository has GitHub private vulnerability reporting enabled, use **Security → Report a vulnerability**. Otherwise, contact the repository maintainer privately through a contact method they explicitly publish in the repository profile or settings.

Reports should include the affected script revision, operating system, a concise reproduction, potential impact, and whether exploitation requires root privileges or local shell access.

## Operational security

- `install` and `apply` run with elevated privileges.
- Installation may install packages and write systemd, udev, init, or hotplug files.
- Modifying Ethernet advertisement can disconnect a remote management session.
- Test changes with independent local or out-of-band recovery access.
- Do not execute a remote shell script without reviewing its contents and provenance.

No compatibility, stability, or security assurance is implied by the presence of this policy.
