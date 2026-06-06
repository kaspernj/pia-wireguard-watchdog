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
scp -O dist/pia-wireguard-watchdog_0.1.1-1_all.ipk root@192.168.86.7:/tmp/
ssh root@192.168.86.7 'opkg install /tmp/pia-wireguard-watchdog_0.1.1-1_all.ipk'
```

Set credentials on the router in `/etc/pia-wireguard.secrets`:

```sh
PIA_USER="your-user"
PIA_PASS="your-password"
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
