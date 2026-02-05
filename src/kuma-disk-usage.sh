#!/usr/bin/env bash

### Post disk usage to Update Kuma ###
#
# Author:      Dirk Henrici
# Created:     2026-02-02
# Last update: 2026-02-05
# License:     MIT


# Posts the disk usage to the provided URL
function postDiskUsageGeneric #(disk, threshold, push_url, type)
{
    disk="$1"
    threshold="$2"
    push_url="$3"
    type="$4"
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
function postDiskUsage #(disk, threshold, push_url)
{
    postDiskUsageGeneric "$1" "$2" "$3" disk
}


# Posts the disk usage to the provided URL
function postMdraidStatus #(device, push_url)
{
    postDiskUsageGeneric "$1" 0 "$2" mdraid
}


# Posts the disk usage to the provided URL
function postDiskUsageZFS #(pool, threshold, push_url)
{
    postDiskUsageGeneric "$1" "$2" "$3" ZFS
}


### Add your query commands here ###

# Example:
# For disks listed with the "df" command; considered down if disk usage exceeds the given threshold (here: 80%)
postDiskUsage "/home" 80 "https://kuma.mydomain.com/api/push/1234567890"

# Example:
# For mdraid device listed with the "mdadm" command; considered down if not in "active" or "clean" state
postMdraidStatus "/dev/md0" "https://kuma.mydomain.com/api/push/1234567890"

# Example:
# For ZFS pools listed with the "zpool list" command; considered down if disk usage exceeds the given threshold (here: 65%) or not in "ONLINE" state
postDiskUsageZFS "tank" 65 "https://kuma.mydomain.com/api/push/1234567890"
