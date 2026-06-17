# Network Scripts

This workspace contains a reusable OpenWrt package for keeping a Private
Internet Access WireGuard client connection alive on a small router.

## PIA WireGuard Watchdog

Package source lives in `package/pia-wireguard-watchdog`.

Build the package locally:

```sh
package/pia-wireguard-watchdog/build-ipk.sh
```

The build writes an architecture-independent OpenWrt package to `dist/`.

Install on an OpenWrt router:

```sh
scp -O dist/pia-wireguard-watchdog_0.1.4-1_all.ipk root@192.168.86.7:/tmp/
ssh root@192.168.86.7 'opkg install /tmp/pia-wireguard-watchdog_0.1.4-1_all.ipk'
```

Set credentials on the router in `/etc/pia-wireguard.secrets`:

```sh
PIA_USER="your-user"
PIA_PASS="your-password"
```

By default, PIA API bootstrap traffic tries the configured LAN gateway first and
then the `.1` gateway on the same LAN. If the configured gateway is not the real
Internet gateway, set the bootstrap gateway explicitly:

```sh
uci set pia-wireguard.main.bootstrap_gateway='192.168.86.1'
uci commit pia-wireguard
```

Then enable and start the service:

```sh
/etc/init.d/pia-wireguard-watchdog enable
/etc/init.d/pia-wireguard-watchdog start
```

Check the watchdog's last health decision:

```sh
cat /var/run/pia-wireguard/status
```

When provisioning runs, the status includes `provision_active_bootstrap_gateway`,
`provision_failed_bootstrap_gateways`, and `provision_last_bootstrap_failure`.
Those fields make it visible when the configured LAN gateway stops providing
DNS or HTTPS bootstrap connectivity.
