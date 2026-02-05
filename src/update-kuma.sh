#!/usr/bin/env bash

### Post disk usage to Update Kuma ###
#
# Author:      Dirk Henrici
# Created:     2026-02-02
# Last update: 2026-02-05
# License:     MIT


# Send a status message to the provided Kuma URL
function postToKuma #(push_url, type, disk, threshold)
{
    push_url="$1"
    type="$2"
    disk="$3"
    threshold="$4"
    percentage="0%"
    health=""
    message=""
    service_status="up"

    case ${type} in
        disk)
            percentage=$(df -hP "${disk}" | tail -1 | awk '{printf "%s", $5}')
            if [[ -z "${percentage}" ]]; then
                echo "Error querying disk usage"
                exit 127
            fi
            # The following text may be changed if desired
            message="Disk usage on ${disk} is ${percentage}"
            ;;
        mdraid)
            health=$(/usr/sbin/mdadm --detail "${disk}" | grep -F "State :" | awk '{printf "%s", $3}')
            if [[ "${health}" != "active" ]] && [[ "${health}" != "clean" ]]; then
                service_status="down"
            fi
            # The following text may be changed if desired
            message="${disk} is ${health}"
            ;;
        ZFS)
            percentage=$(/usr/sbin/zpool list "${disk}" | tail -1 | awk '{printf "%s", $8}')
            health=$(/usr/sbin/zpool list "${disk}" | tail -1 | awk '{printf "%s", $10}')
            if [[ "${health}" != "ONLINE" ]]; then
                service_status="down"
            fi
            # The following text may be changed if desired
            message="Disk usage on ${disk} is ${percentage}, status ${health}"
            ;;
        *)
            echo "Type not recognized."
            exit 127
            ;;
    esac

    number=${percentage%\%*}
    if [[ ${number} -gt ${threshold} ]]; then
        service_status="down"
    fi

    echo "Posting status '${service_status}' with message '${message}'"
    curl \
      --get \
      --data-urlencode "status=${service_status}" \
      --data-urlencode "msg=${message}" \
      --data-urlencode "ping=${number}" \
      --silent \
      -o /dev/null \
      "${push_url}"
}


# Posts the disk usage to the provided URL
function postDiskUsage #(push_url, disk, threshold)
{
    postToKuma "$1" disk "$2" "$3"
}


# Posts the disk usage to the provided URL
function postMdraidStatus #(push_url, device)
{
    postToKuma "$1" mdraid "$2" 0
}


# Posts the disk usage to the provided URL
function postDiskUsageZFS #(push_url, pool, threshold)
{
    postToKuma "$1" ZFS "$2" "$3"
}


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
