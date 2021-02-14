#!/bin/sh

# If running as root (first invocation), fix mountpoint permissions
# and re-run this script as appuser.
if [ $(id -u) -eq 0 ]; then
  mkdir -p /store/last
  mkdir -p /store/ghash
  chown -R appuser:appuser /store /config
  exec su appuser -- "$0" "$@"
fi

# Load Default recorder.conf if not available
if [ ! -f /config/recorder.conf ]; then
	  cp /etc/default/recorder.conf /config/recorder.conf
fi

/usr/sbin/ot-recorder --initialize
/usr/sbin/ot-recorder "$@"
