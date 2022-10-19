#!/bin/sh
######################################
#     Find/Remove Printers Script    #
#        Max Hewett 14/10/22         #
######################################

### Variables ###

#################

## Remove incorrect printers ##
    for The_Printer1 in  $(lpstat -v | awk '/lpd:/ {print $3}' | rev | cut -c2- | rev); do
    echo removing ${The_Printer1}
    lpadmin -x ${The_Printer1}
    done
    
    for The_Printer3 in  $(lpstat -v | awk '/RICOH/ {print $3}' | rev | cut -c2- | rev); do
    echo removing ${The_Printer3}
    lpadmin -x ${The_Printer3}
    done

    for The_Printer3 in  $(lpstat -v | awk '/Brother/ {print $3}' | rev | cut -c2- | rev); do
    echo removing ${The_Printer3}
    lpadmin -x ${The_Printer3}
    done

## Kill, Clear PrintDeploy ##
	# kill PrintDeploy #
	killall usercontextservice
    launchctl unload "/Library/LaunchAgents/com.papercut.printdeploy.client.plist"
    echo "Killed PrintDeploy process & LaunchAgent"
    #delete old printdeploy files
    rm -rf /Applications/PaperCut\ Print\ Deploy\ Client/data/logs/pc-print-deploy-client.log
    echo "Deleted PrintDeploy log"
    rm -rf /Applications/PaperCut\ Print\ Deploy\ Client
    echo "Cleared out old PrintDeploy files"

## Run Papercut policy to update UserClient and PrintDeploy ##
	# Papercut Policy #
    echo "Running Papercut policy"
	/usr/local/jamf/bin/jamf policy -trigger dep-Papercut
    # relaunch PrintDeploy #
    launchctl load "/Library/LaunchAgents/com.papercut.printdeploy.client.plist"
    echo "Relaunched PrintDeploy"
    
# Check if script has worked
echo "Allowing time for log file to be recreated"
sleep 20
if "$(cat /Applications/PaperCut\ Print\ Deploy\ Client/data/logs/pc-print-deploy-client.log | grep 10.35.2.50:9174 | awk '{print $9}')"; then
            echo "Confirmed correct PaperCut server IP address set"
        else
            echo "Incorrect PaperCut server IP address set"
            exit 1
    fi
exit 0
