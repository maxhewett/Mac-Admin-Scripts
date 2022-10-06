#!/bin/sh
######################################
#     Find/Remove Printers Script    #
#        Max Hewett 14/09/22         #
#             Cyclone                #
######################################

### Variables ###

#################

## Remove incorrect printers ##
	for The_Printer3 in  $(lpstat -v | awk '/Follow/ {print $3}' | rev | cut -c2- | rev); do
	echo removing ${The_Printer3}
	lpadmin -x ${The_Printer3}
	done

## Re-run PrintDeploy ##
	# kill PrintDeploy #
	killall usercontextservice
	# relaunch PrintDeploy #
	launchctl load "/Library/LaunchAgents/com.papercut.printdeploy.client.plist"

## Run Papercut policy to update UserClient and PrintDeploy ##
	# Papercut Policy #
	/usr/local/jamf/bin/jamf policy -trigger dep-Papercut
    # Open UserClient #
    sleep 120
    echo = "waiting 2 minutes for Papercut policy to finish..."
	launchctl load -w "/Library/LaunchAgents/biz.papercut.pcng.plist"
echo "removed printers, ran PrintDeploy, updated/relaunched Papercut client & PrintDeploy"
exit 0