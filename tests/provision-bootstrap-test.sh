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
CURRENT_GATEWAY=""
ROUTE_LOG=""

ip() {
	if [ "$1" = "route" ] && [ "$2" = "replace" ]; then
		ROUTE_LOG="${ROUTE_LOG}${ROUTE_LOG:+
}$*"
		CURRENT_GATEWAY="$5"
		return 0
	fi

	return 1
}

nslookup() {
	if [ "$CURRENT_GATEWAY" = "192.168.86.1" ]; then
		printf "Server:\t\t%s\n" "$2"
		printf "Address:\t%s:53\n\n" "$2"
		printf "Non-authoritative answer:\n"
		printf "Name:\t%s\n" "$1"
		printf "Address: 104.19.240.167\n"
		return 0
	fi

	return 1
}

curl() {
	printf "%s\n" "$*" > "$TMP_DIR/curl.log"
	printf "server-list-response"
}

logger() {
	return 0
}

ip route replace probe via 192.168.86.3 dev br-lan.86
case "$ROUTE_LOG" in
	*"route replace probe via 192.168.86.3 dev br-lan.86"*) ;;
	*)
	printf "Fake ip command did not write route log.\n" >&2
	exit 1
	;;
esac
ROUTE_LOG=""
CURRENT_GATEWAY=""

BOOTSTRAP_INTERFACE="br-lan.86"
BOOTSTRAP_GATEWAYS="192.168.86.3 192.168.86.1"
BOOTSTRAP_DNS="9.9.9.9"

if ! curl_bootstrap "https://serverlist.piaservers.net/vpninfo/servers/v6"; then
	printf "curl_bootstrap failed unexpectedly.\n\nRoutes:\n" >&2
	printf "%s\n" "$ROUTE_LOG" >&2
	exit 1
fi
response="$BOOTSTRAP_CURL_RESPONSE"

[ "$response" = "server-list-response" ] || {
	printf "Unexpected curl response: %s\n" "$response" >&2
	exit 1
}

case "$ROUTE_LOG" in
	*"route replace 104.19.240.167 via 192.168.86.1 dev br-lan.86"*) ;;
	*)
		printf "Expected serverlist HTTPS route through fallback gateway.\n\nRoutes:\n%s\n" "$ROUTE_LOG" >&2
		exit 1
	;;
esac
