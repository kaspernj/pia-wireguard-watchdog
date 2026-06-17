#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
PROVISIONER="$REPO_DIR/package/pia-wireguard-watchdog/files/usr/sbin/pia-wireguard-provision"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

awk '/^main "\$@"/ { exit } { print }' "$PROVISIONER" > "$TMP_DIR/provision-functions.sh"
. "$TMP_DIR/provision-functions.sh"

STATE_DIR="$TMP_DIR"
INTERFACE="wg0_pia"
REGION="swiss"
BOOTSTRAP_INTERFACE="br-lan.86"
BOOTSTRAP_GATEWAYS="192.168.86.3 192.168.86.1"
BOOTSTRAP_DNS="9.9.9.9"
ACTIVE_BOOTSTRAP_GATEWAY="192.168.86.1"
FAILED_BOOTSTRAP_GATEWAYS="192.168.86.3"
LAST_BOOTSTRAP_FAILURE="bootstrap DNS 9.9.9.9 via 192.168.86.3 did not resolve serverlist.piaservers.net"

write_provision_status success provisioned

assert_status_line() {
	local expected="$1"
	local status_file="$STATE_DIR/provision-status"

	grep -Fqx "$expected" "$status_file" || {
		printf "Expected provision status line missing: %s\n\n" "$expected" >&2
		cat "$status_file" >&2
		exit 1
	}
}

assert_status_line "state=success"
assert_status_line "reason=provisioned"
assert_status_line "interface=wg0_pia"
assert_status_line "region=swiss"
assert_status_line "bootstrap_interface=br-lan.86"
assert_status_line "bootstrap_gateways=192.168.86.3 192.168.86.1"
assert_status_line "active_bootstrap_gateway=192.168.86.1"
assert_status_line "bootstrap_dns=9.9.9.9"
assert_status_line "failed_bootstrap_gateways=192.168.86.3"
assert_status_line "last_bootstrap_failure=bootstrap DNS 9.9.9.9 via 192.168.86.3 did not resolve serverlist.piaservers.net"
