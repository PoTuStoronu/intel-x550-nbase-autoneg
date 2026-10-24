#!/bin/sh
# X550 copper NBASE-T auto advertisement for Debian/Ubuntu/PVE/OpenWrt.
set -u

TARGET=/usr/local/sbin/x550-nbase.sh
MASK=0x1800000001028

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

is_x550_copper() {
    iface=$1
    sys=/sys/class/net/$iface/device
    [ -f "$sys/vendor" ] && [ -f "$sys/device" ] && [ -L "$sys/driver" ] || return 1
    [ "$(cat "$sys/vendor")" = '0x8086' ] || return 1
    [ "$(basename "$(readlink "$sys/driver")")" = ixgbe ] || return 1
    case "$(cat "$sys/device")" in
        0x1563|0x15d1|0x15ad|0x15c8) return 0 ;;
        *) return 1 ;;
    esac
}

# Extract the link-mode section, stopping at the next ethtool field.
# Works with both full lines and wrapped continuation lines.
modes() {
    printf '%s\n' "$1" | awk -v header="$2" '
        index($0, header) == 1 || $0 ~ "^[[:space:]]*" header {
            found=1
            sub(/^.*:[[:space:]]*/, "")
            print
            next
        }
        found {
            if ($0 ~ /^[[:space:]]+[[:digit:]]+(base|BASE)/) { print; next }
            exit
        }
    '
}

has_all() {
    data=$1
    for speed in 100baseT/Full 1000baseT/Full 2500baseT/Full 5000baseT/Full 10000baseT/Full; do
        printf '%s\n' "$data" | grep -Fq "$speed" || return 1
    done
}

apply() {
    if ! command -v ethtool >/dev/null 2>&1; then
        warn "ethtool not installed; install it first (apt/opkg/apk)."
        return 1
    fi
    matched=0
    errors=0
    for entry in /sys/class/net/*; do
        [ -e "$entry" ] || continue
        dev=${entry##*/}
        is_x550_copper "$dev" || continue
        matched=$((matched + 1))
        current=$(ethtool "$dev" 2>/dev/null) || {
            warn "$dev: cannot read ethtool capabilities"
            errors=$((errors + 1))
            continue
        }
        supported=$(modes "$current" 'Supported link modes:')
        if ! has_all "$supported"; then
            warn "$dev: X550 copper ID found, but hardware/driver does not report all five speeds; skipped"
            continue
        fi
        advertised=$(modes "$current" 'Advertised link modes:')
        if has_all "$advertised" && printf '%s\n' "$current" | grep -Eq '^[[:space:]]*Auto-negotiation: on'; then
            say "$dev: all five speeds already advertised; unchanged"
            continue
        fi
        if ethtool -s "$dev" autoneg on advertise "$MASK"; then
            say "$dev: enabled 100M/1G/2.5G/5G/10G advertisement ($MASK)"
        else
            warn "$dev: ethtool rejected settings; existing configuration was not intentionally altered"
            errors=$((errors + 1))
        fi
    done
    [ "$matched" -ne 0 ] || say 'No supported Intel X550 copper interfaces detected; no changes.'
    [ "$errors" -eq 0 ]
}

status() {
    if ! command -v ethtool >/dev/null 2>&1; then warn 'ethtool is missing'; return 1; fi
    matched=0
    for entry in /sys/class/net/*; do
        [ -e "$entry" ] || continue
        dev=${entry##*/}
        is_x550_copper "$dev" || continue
        matched=$((matched+1))
        say "===== $dev ====="
        ethtool "$dev" | grep -E -A 8 'Supported link modes:|Advertised link modes:' || true
        ethtool "$dev" | grep -E '^[[:space:]]*(Speed:|Auto-negotiation:|Link detected:)' || true
    done
    [ "$matched" -ne 0 ] || say 'No supported X550 copper interfaces found.'
}

require_root() { [ "$(id -u)" -eq 0 ] || { warn 'Run as root'; exit 1; }; }

install_debian() {
    command -v systemctl >/dev/null 2>&1 || { warn 'systemctl not found'; return 1; }
    cat > /etc/systemd/system/x550-nbase.service <<'EOF'
[Unit]
Description=Enable Intel X550 all-speed NBASE-T advertisement
After=systemd-udev-trigger.service
ConditionPathExists=/usr/local/sbin/x550-nbase.sh

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/x550-nbase.sh apply

[Install]
WantedBy=multi-user.target
EOF
    cat > /etc/udev/rules.d/80-x550-nbase.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="net", DRIVERS=="ixgbe", TAG+="systemd", ENV{SYSTEMD_WANTS}+="x550-nbase.service"
EOF
    systemctl daemon-reload
    udevadm control --reload-rules 2>/dev/null || true
    systemctl enable x550-nbase.service
}

install_openwrt() {
    mkdir -p /etc/hotplug.d/net /etc/init.d
    cat > /etc/init.d/x550-nbase <<'EOF'
#!/bin/sh /etc/rc.common
START=95
STOP=10
start() {
    /usr/local/sbin/x550-nbase.sh apply
}
EOF
    chmod 755 /etc/init.d/x550-nbase
    cat > /etc/hotplug.d/net/95-x550-nbase <<'EOF'
#!/bin/sh
[ "${ACTION:-}" = add ] || exit 0
/usr/local/sbin/x550-nbase.sh apply
EOF
    chmod 755 /etc/hotplug.d/net/95-x550-nbase
    /etc/init.d/x550-nbase enable
}

install() {
    require_root
    if ! command -v ethtool >/dev/null 2>&1; then
        if [ -f /etc/openwrt_release ]; then
            if command -v apk >/dev/null 2>&1; then
                apk update && apk add ethtool || return 1
            elif command -v opkg >/dev/null 2>&1; then
                opkg update && opkg install ethtool || return 1
            else
                warn 'No OpenWrt package manager found; please install ethtool first'
                return 1
            fi
        elif command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y ethtool || return 1
        else
            warn 'Please install ethtool manually'
            return 1
        fi
    fi
    mkdir -p /usr/local/sbin
    src=$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")
    if [ "$src" != "$TARGET" ]; then cp "$0" "$TARGET" || return 1; fi
    chmod 755 "$TARGET"
    if [ -f /etc/openwrt_release ]; then
        install_openwrt || return 1
        say 'Installed OpenWrt boot service and net hotplug hook.'
    else
        install_debian || return 1
        say 'Installed systemd boot service and udev hook.'
    fi
    say 'Installation complete. Apply now with: sh /usr/local/sbin/x550-nbase.sh apply'
}

uninstall() {
    require_root
    if [ -f /etc/openwrt_release ]; then
        [ ! -e /etc/init.d/x550-nbase ] || /etc/init.d/x550-nbase disable
        rm -f /etc/init.d/x550-nbase /etc/hotplug.d/net/95-x550-nbase
    else
        if command -v systemctl >/dev/null 2>&1; then
            systemctl disable x550-nbase.service 2>/dev/null || true
        fi
        rm -f /etc/systemd/system/x550-nbase.service /etc/udev/rules.d/80-x550-nbase.rules
        if command -v systemctl >/dev/null 2>&1; then systemctl daemon-reload; fi
        if command -v udevadm >/dev/null 2>&1; then udevadm control --reload-rules; fi
    fi
    rm -f "$TARGET"
    say 'Removed hooks and script. Existing link advertisement is unchanged until reset/reload.'
}

case "${1:-apply}" in
    apply) require_root; apply ;;
    status) status ;;
    install) install ;;
    uninstall) uninstall ;;
    *) say "Usage: sh $0 {install|apply|status|uninstall}"; exit 2 ;;
esac
