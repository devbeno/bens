#!/bin/bash

# Bash helper functions
include "lib/helpers.sh"
verify_esh

# Digital Ocean API
include "lib/doctl.sh"
verify_doctl

if undefined $SWARM; then
  echo
  echo "Usage:  $CMD_NAME inspect SWARM"
  echo
  exit 1
fi

# Check if swarmfile exists
if hasnt $SWARMFILE; then
  echo_stop "Swarm named \"${SWARM}\" not found:"
  echo $SWARMFILE
  echo
  exit 1
fi

# Get primary and its size
PRIMARY=$(get_swarm_primary)
VOLUME_SIZE=$(get_volume_size $PRIMARY)
DROPLET_SIZE=$(get_droplet_size $PRIMARY)

# Environment Variables
include "lib/env.sh"

INSPECT_ONLY=1
include "command/provision.sh"
