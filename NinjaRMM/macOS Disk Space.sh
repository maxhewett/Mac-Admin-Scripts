#!/bin/sh
######################################
#  NinjaRMM Disk Space Usage Script  #
#        Max Hewett 17/11/22         #
######################################

## Variables ##


diskutil_list_plist="$(diskutil list -plist)"

diskutil_mount_points_count="$(echo "${diskutil_list_plist}" | xmllint --xpath 'count(//key[text()="MountPoint"])' -)"

diskutil_mount_points_array=()

for (( this_index = 1; this_index <= diskutil_mount_points_count; this_index ++ )); do
	diskutil_mount_points_array+=( "$(echo "${diskutil_list_plist}" | xmllint --xpath "(//key[text()='MountPoint']/following-sibling::string[1])[${this_index}]/text()" -)" )
done

IFS=$'\n'
echo "${diskutil_mount_points_array[*]}"
unset IFS