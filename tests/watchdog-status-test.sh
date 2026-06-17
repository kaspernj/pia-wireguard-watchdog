#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
WATCHDOG="$REPO_DIR/package/pia-wireguard-watchdog/files/usr/sbin/pia-wireguard-watchdog"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

awk '/^main_loop "\$@"/ { exit } { print }' "$WATCHDOG" > "$TMP_DIR/watchdog-functions.sh"
. "$TMP_DIR/watchdog-functions.sh"

STATE_DIR="$TMP_DIR"
STATUS_FILE="$TMP_DIR/status"
INTERFACE="wg0_pia"
HEALTH_REASON="stale_handshake:missing"
HANDSHAKE_AGE="missing"
EGRESS_RESULT="not_checked"

cat > "$STATE_DIR/provision-status" <<'STATUS'
state=success
active_bootstrap_gateway=192.168.86.1
bootstrap_gateways=192.168.86.3 192.168.86.1
failed_bootstrap_gateways=192.168.86.3
last_bootstrap_failure=bootstrap DNS 9.9.9.9 via 192.168.86.3 did not resolve serverlist.piaservers.net
STATUS

write_status unhealthy provision_failed

assert_status_line() {
	local expected="$1"

	grep -Fqx "$expected" "$STATUS_FILE" || {
		printf "Expected status line missing: %s\n\n" "$expected" >&2
		cat "$STATUS_FILE" >&2
		exit 1
	}
}

assert_status_line "provision_state=success"
assert_status_line "provision_active_bootstrap_gateway=192.168.86.1"
assert_status_line "provision_bootstrap_gateways=192.168.86.3 192.168.86.1"
assert_status_line "provision_failed_bootstrap_gateways=192.168.86.3"
assert_status_line "provision_last_bootstrap_failure=bootstrap DNS 9.9.9.9 via 192.168.86.3 did not resolve serverlist.piaservers.net"
