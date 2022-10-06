#!/bin/sh

apiUsername=$4
apiPassword=$5
jamfProURL="https://ranrur01.jamfcloud.com/"
macSerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
jamfProCompID=$(curl -s -u $apiUsername:$apiPassword -H "Accept: text/xml" "$jamfProURL"/JSSResource/computers/serialnumber/"$macSerial" | xmllint --xpath '/computer/general/id/text()' -)

/usr/bin/curl -s -X POST -H "Content-Type: text/xml" -u ${apiUsername}:${apiPassword} ${jamfProURL}/JSSResource/computercommands/command/ScheduleOSUpdate/action/install/id/${jamfProCompID}
