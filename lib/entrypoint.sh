#!/bin/bash

# Start tailscaled in the background, registering the daemon as ephemeral and
# using userspace networking.
tailscaled --tun=userspace-networking --state=mem: 2>~/tailscaled.log &

# Switch to the `run` command we specify in the `ops.yml` file for this workflow
# using the `exec` command, which replaces the current process with the new one
# we pass in as arguments.
exec "$@"
