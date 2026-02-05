#!/usr/bin/env bash

# The following commands make several operations available for your use.
# The "push-to-kuma" script is expected to be in the same directory as the currently executed script.
script_dir="$(dirname "${BASH_SOURCE[0]}")"
source "${script_dir}/push-to-kuma"

### Add your query commands here ###

# Example:
# For disks listed with the "df" command; considered down if disk usage exceeds the given threshold (here: 80%)
postDiskUsage "https://kuma.mydomain.com/api/push/1234567890" "/home" 80

# Example:
# For mdraid device listed with the "mdadm" command; considered down if not in "active" or "clean" state
postMdraidStatus "https://kuma.mydomain.com/api/push/1234567890" "/dev/md0"

# Example:
# For ZFS pools listed with the "zpool list" command; considered down if disk usage exceeds the given threshold (here: 65%) or not in "ONLINE" state
postDiskUsageZFS "https://kuma.mydomain.com/api/push/1234567890" "tank" 65
