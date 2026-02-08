# push-to-kuma
Send disk usage information and status via https push to an Uptime Kuma instance

---

## Features

- Can query disk usage information
- Can query mdraid status, especially for working mirroring
- Can query ZFS zpool status and usage information
- Just Bash shell and common system tools required, no other dependencies
- Simple configuration
- Just two files and a cron job; thus easily deployable using configuration management tools like Ansible and Saltstack
- Compatible to off-the-shelf Uptime Kuma

---

## Installation & Configuration

*Installation*

1. Save the two files from the src folder in this repository into an arbitrary directory (e.g. "/home/scripts") and make them executable ("chmod u+x <name>").
2. Add the line "\*/5 * * * * /home/scripts/update-kuma.sh" into your crontab, e.g. by editing it using "crontab -e", to call the script every five minutes. Don't forget to adjust the file path if required.

*Configuration*

1. Configure all desired regular checks in Uptime Kuma with "Monitor Type" "Push" with 300 second interval (at least; I use a more conservative 320 second interval).
2. Edit "update-kuma.sh" to add and configure all desired regular checks with the Push URLs displayed in Update Kuma.

---

## Available Checks

### Disk Usage

*Queries the usage status of a disk*

`postDiskUsage "<push_url>" "<disk mount point>" <threshold>`

For disks listed with the "df" command; considered down if disk usage exceeds the given threshold (here: 80%).

Parameters:
1. "push_url": Push URL listed in Update Kuma. Omit the query string.
2. "disk mount point": Mount point of the file system to be monitored.
3. "threshold": Percentage of disk filling level; exceeding it posts a down state.

Example:
* `postDiskUsage "https://kuma.mydomain.com/api/push/1234567890" "/home" 80`

### Mdraid Status

*Queries the state of an mdraid disk array*

`postMdraidStatus "<push_url>" "<mdraid disk>"`

For mdraid device listed with the "mdadm" command; considered down if not in "active" or "clean" state.

Parameters:
1. "push_url": Push URL listed in Update Kuma. Omit the query string.
2. "mdraid disk": Device path of mdraid array to be monitored.

Example:
* `postMdraidStatus "https://kuma.mydomain.com/api/push/1234567890" "/dev/md0"`

### ZFS Pool Status

*Queries the usage status of a ZFS pool*

`postDiskUsageZFS "<push_url>" "<zpool>" <threshold>`

For ZFS pools listed with the "zpool list" command; considered down if disk usage exceeds the given threshold (here: 65%) or not in "ONLINE" state.

Parameters:
1. "push_url": Push URL listed in Update Kuma. Omit the query string.
2. "zpool": ZFS pool to be monitored.
3. "threshold": Percentage of pool filling level; exceeding it posts a down state.

Example:
* `postDiskUsageZFS "https://kuma.mydomain.com/api/push/1234567890" "tank" 65`

---

## Reporting bugs

In case you encounter any bugs, please report the expected behavior and the actual behavior so that the issue can be reproduced and fixed.

---

## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

- **[MIT license](https://opensource.org/licenses/MIT)**
- Copyright 2026 © <a href="https://github.com/towalink/push-to-kuma" target="_blank">Dirk Henrici</a>.
