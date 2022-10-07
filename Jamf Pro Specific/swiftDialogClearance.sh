#!/bin/sh
######################################
#   Medbury Decommissioning Script   #
#        Max Hewett 07/10/22         #
#             Cyclone                #
######################################


### Variables ###
adminUser="ladmin"
adminPass="t@llEarth81"
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//')
JAMF_SERIAL=$(system_profiler SPHardwareDataType | grep 'Serial Number (system)' | awk '{print $NF}')
JamfID=`curl -H "Accept: text/xml" -sfku "${4}:${5}" "${jssURL}/JSSResource/computers/serialnumber/${JAMF_SERIAL}/subset/general" | xpath -e '/computer/general/id/text()'`
swiftDialogInstalled=$(test -f /usr/local/bin/dialog && echo "yes")

#################
# use jamf variables so they're stored before the mac is unenrolled
echo "$JamfID -  JSS Computer ID"
echo "$jssURL - JSS URL"
#################

enrol_initial_policy_start "$(date +%s)"

jamf_binary="/usr/local/bin/jamf"
fde_setup_binary="/usr/bin/fdesetup"
log_folder="/private/var/log"
log_name="goodbye.log"

dialog_app="/usr/local/bin/dialog"
dialog_command_file="/var/tmp/dialog.log"
dialog_icon="/Library/Management/Images/logo.png"
dialog_title="Medbury Clearance"
dialog_title_complete="You're all done"
dialog_message="Let's get started. \n\n There are a few things to do in order to de-provision your Mac. \n\n This process should take about 1 to 2 minutes to complete."
dialog_status_initial="Clearance Initialising..."
dialog_status_complete="Clearance Complete!"

dialog_cmd=(
    "-p --title \"$dialog_title\""
    "--iconsize 200"
    "--width 70%"
    "--height 70%"
    "--position centre"
    "--progress 30"
    "--progresstext \"$dialog_status_initial\""
)

#########################################################################################
# Policy Array to determine what's installed
#########################################################################################

policy_array=('
{
    "steps": [
        {
            "listitem": "Removing Printers...",
            "icon": "SF=printer.filled.and.paper,colour=auto,weight=medium",
            "trigger_list": [
                {
                    "trigger": "reset_CUPS"
                },
                {
                    "trigger": "remove_copiers"
                }
            ]
        },
        {
            "listitem": "Removing apps...",
            "icon": "SF=questionmark.app.dashed,colour=auto,weight=medium",
            "trigger_list": [
                {
                    "trigger": "remove_apps"
                }
            ]
        },
        {
            "listitem": "Removing Previous MDM Remnants...",
            "icon": "SF=command.square.fill,colour=auto,weight=medium",
            "trigger_list": [
                {
                    "trigger": "remove_munki_remnants"
                }
            ]
        },
        {
            "listitem": "Performing User Operations...",
            "icon": "SF=person.badge.minus,colour=multicolour,weight=medium",
            "trigger_list": [
                {
                    "trigger": "Get_Password"
                },
                {
                    "trigger": "elevate_User"
                },
                {
                    "trigger": "remove_Ladmin"
                }
            ]
        },
        {
            "listitem": "Removing MDM Components...",
            "icon": "SF=command.square.fill,colour=auto,weight=medium",
            "trigger_list": [
                {
                    "trigger": "removefrom_JSS"
                },
                {
                    "trigger": "remove_jamf"
                }
            ]
        }
    ]
}
')

#########################################################################################
# Bash functions used later on
#########################################################################################

echo_logger() {
    log_folder="${log_folder:=/private/var/log}"
    log_name="${log_name:=log.log}"

    mkdir -p $log_folder

    echo -e "$(date) - $1" | tee -a $log_folder/$log_name
}

dialog_update() {
    echo_logger "DIALOG: $1"
    # shellcheck disable=2001
    echo "$1" >> "$dialog_command_file"
}

get_json_value() {
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
}

run_clear_trigger() {
    trigger="$1"
    if [ "$testing_mode" = true ]; then
        echo_logger "TESTING: $step"
        sleep 1
    elif [ "$step" == "recon" ]; then
        echo_logger "RUNNING: $jamf_binary $step"
        "$jamf_binary" "$step"
    else
        echo_logger "RUNNING: $jamf_binary policy -event $step"
        "$step_sh"
    fi
}

reset_CUPS() {

#Stop the CUPS daemon with the following command.
launchctl stop org.cups.cupsd

#Rename the old CUPS configuration file.
mv /etc/cups/cupsd.conf /etc/cups/cupsd.conf.backup

#Restore the default settings file.
cp /etc/cups/cupsd.conf.default /etc/cups/cupsd.conf

#Rename printers file.
mv /etc/cups/printers.conf /etc/cups/printers.conf.backup

#Restart CUPS.
launchctl start org.cups.cupsd
dialog_update "progresstext: Reset CUPS"
sleep 5

}

remove_copiers() {

lpadmin -x Medbury_Colour_Copier
dialog_update "progresstext: Removed colour copier"
sleep 2

lpadmin -x Medbury_Grayscale_Copier
dialog_update "progresstext: Removed grayscale copier"

sleep 5
}

remove_apps() {

#Lego EV3
rm -rf /Applications/EV3\ Classroom.app
dialog_update "progresstext: Removed Lego EV3 app"
sleep 2

#Zoom
rm -rf /Applications/zoom.us.app
rm -rf /Library/LaunchDaemons/us.zoom.ZoomDaemon.plist
dialog_update "progresstext: Removed Zoom app"

#Scratch 3/Scratch Link
rm -rf /Applications/Scratch\ 3.app
rm -rf /Applications/Scratch\ Link.app
dialog_update "progresstext: Removed Scratch apps"
sleep 2

#SimpleMind
rm -rf /Applications/SimpleMind.app
dialog_update "progresstext: Removed Simplemind app"
sleep 2

#Remove Papercut
rm -rf /Applications/PCClient.app
dialog_update "progresstext: Removed Papercut client"
sleep 2

#Remove Up Studio
rm -rf /Applications/Up\ Studio.app
dialog_update "progresstext: Removed Up Studio"
sleep 2

#Remove Janison Replay
rm -rf /Applications/Janison\ Replay.app
rm /Users/$loggedInUser/Desktop/Janison\ Replay
dialog_update "progresstext: Removed Janison Replay"

sleep 5
}

remove_munki_remnants(){

## Remove Munki Launchagents etc. ##
rm -rf /Applications/Managed\ Software\ Centre.app
rm -Rf /usr/local/munki
rm -Rf /usr/local/munkireport

rm -Rf /Library/Preferences/ManagedInstalls.plist

rm -Rf /Library/LaunchDaemons/com.googlecode.munki*
rm -Rf /Library/LaunchDaemons/com.github.munkireport*
dialog_update "progresstext: Removed munki remnants"

sleep 5
}

Get_Password()
{
dialog_update "progresstext: Please enter your password in the pop-up"
sleep 2
USERPASSWORD=$(/usr/bin/osascript << EOF
activate
display dialog "Enter the password for $loggedInUser." default answer "password" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
set UserPassword to text returned of result
EOF)
}

# Make sure if the password is typed incorrectly & prompted for again, it is stored in both variables
merge_Passwords()
{
if [$USERPASSWORD != $USERPASSWORD2 ]; then
echo "passwords the same already"
else
USERPASSWORD="$USERPASSWORD2"
echo "fixed passwords"
fi

elevate_User
}

# Capture the user password into a variable (again)
GetPasswordifFailed()
{
USERPASSWORD2=$(/usr/bin/osascript << EOF
activate
display dialog "Incorrect password for $loggedInUser. Please try again" default answer "$USERPASSWORD" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
set UserPassword to text returned of result
EOF)
merge_Passwords
dialog_update "rogresstext: Please try your password again"
sleep 2
}

# Make student user an admin
function elevate_User()
{
if [ "$loggedInUser" == "$adminUser" ]; then
$(/usr/bin/osascript << EOF
activate
display alert "You are currently logged in as $adminUser. Please login with the account you'd like to use going forward." with title "Logged in as wrong user!" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
EOF)
else
dscl . -append /groups/admin GroupMembership $loggedInUser
echo "made $loggedInUser admin user. Now moving Secure Token..."
AddSecureToken
fi
dialog_update "progresstext: Elevated $loggedInUser to administrator"
sleep 2
}

#Add Secure Token to local user
function AddSecureToken()
{
echo "adding securetoken to $loggedInUser..."
if [[ $(sysadminctl -adminUser $adminUser -adminPassword $adminPass -secureTokenOn $loggedInUser -password $USERPASSWORD 2>&1) != *"- Done!"* ]] ; then
echo "admin password incorrect, re-prompting user"
GetPasswordifFailed
else
dialog_update "progresstext: Securetoken added! Confirming with sysadminctl..."
sleep 2
dialog_update "progresstext: $(sysadminctl -secureTokenStatus $loggedInUser)"
sleep 2
dialog_update "progresstext: Updating preboot to allow student to unlock disk"
sleep 2
diskutil apfs updatepreboot
dialog_update "progresstext: SecureToken added, now removing SecureToken from $adminUser"
sleep 2
MoveSecureToken
fi
}

#Remove Secure Token from ladmin
function MoveSecureToken()
{
dialog_update "progresstext: Removing securetoken from $adminUser..."
sleep 2
if [[ $(sysadminctl -adminUser $loggedInUser -adminPassword $USERPASSWORD -secureTokenOff $adminUser -password $adminPass 2>&1) != *"- Done!"* ]] ; then
echo "admin password incorrect, re-prompting user"
GetPasswordifFailed
else
dialog_update "progresstext: SecureToken removed! Confirming with sysadminctl..."
sleep 2
dialog_update "progresstext: $(sysadminctl -secureTokenStatus $adminUser)"
sleep 2
dialog_update "progresstext: Updating preboot to allow $loggedInUser to unlock disk"
sleep 2
diskutil apfs updatepreboot

dialog_update "progresstext: SecureToken operations complete, now removing $adminUser"
sleep 2
fi
}

#remove ladmin
function remove_Ladmin()
{
# Check if our admin has a Secure Token
if [[ $("/usr/sbin/sysadminctl" -secureTokenStatus $adminUser 2>&1) =~ "ENABLED" ]]; then
adminToken="true"
sudo dscl . create /Users/ladmin IsHidden 1
dialog_update "progresstext: $adminUser has securetoken, cannot be deleted. User hidden instead."
sleep 2
$(/usr/bin/osascript << EOF
activate
display alert "Could not remove $adminUser. Please bring your laptop to IT to finish the clearance process." with title "Error" with icon caution
EOF)
else
adminToken="false"
/usr/bin/dscl . -delete /Users/ladmin
rm -rf /Users/ladmin
dialog_update "progresstext: $adminUser has no SecureToken and has been deleted."
sleep 2
fi

}


removefrom_JSS() {

dialog_update "progresstext: Removing Mac from Jamf Pro Server..."
sleep 2
if [ $(curl -s -k -u "${4}:${5}" "${jssURL}/JSSResource/computers/id/${JamfID}" -X DELETE) ] ; then
dialog_update "progresstext: Successfully removed Mac from Jamf Pro Server."
sleep 2
else
dialog_update "progresstext: Failed to remove Mac from Jamf Pro Server, Remove manually"
sleep 5
fi

}

remove_jamf() {

## Remove jamf binary & unenroll ##
sudo killall Self\ Service
dialog_update "progresstext: Quit Self Service app"
jamf -removeMdmProfile
jamf -removeFramework
dialog_update "progresstext: Removed jamf binary"

}

cleanup_stuff() {
rm -r /Library/Management/Images/
}
#########################################################################################
# Policy kickoff
#########################################################################################

# Check if Dialog is running
if [ ! "$(pgrep -x "dialog")" ]; then
    echo_logger "INFO: Dialog isn't running, launching now"
    eval "$dialog_app" "${dialog_cmd[*]}" & sleep 1
else
    echo_logger "INFO: Dialog is running"
    dialog_update "title: $dialog_title"
    dialog_update "progresstext: $dialog_status_initial"
fi

dialog_update "progress: complete"

logged_in_user=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
logged_in_user_uid=$(id -u "$logged_in_user")
echo_logger "Current user set to $logged_in_user."


#########################################################################################
# Main Script Logic
#########################################################################################

# Iterate through policy_array json to construct the list for swiftDialog
dialog_step_length=$(get_json_value "${policy_array[*]}" "steps.length")
for (( i=0; i<dialog_step_length; i++ )); do
    listitem=$(get_json_value "${policy_array[*]}" "steps[$i].listitem")
    list_item_array+=("$listitem")
done

# Updating swiftDialog with the list of items
dialog_update "icon: default"
dialog_update "icon: $dialog_icon"
dialog_update "message: $dialog_message"
dialog_update "progresstext: "

list_item_string=${list_item_array[*]/%/,}
dialog_update "list: ${list_item_string%?}"
for (( i=0; i<dialog_step_length; i++ )); do
    dialog_update "listitem: index: $i, status: pending"
done
# The ${array_name[*]/%/,} expansion will combine all items within the array adding a "," character at the end
# To add a character to the start, use "/#/" instead of the "/%/"

if [ "$testing_mode" = true ]; then sleep 2; fi

# This for loop will iterate over each distinct step in the policy_array array
for (( i=0; i<dialog_step_length; i++ )); do
    # Creating initial variables
    listitem=$(get_json_value "${policy_array[*]}" "steps[$i].listitem")
    icon=$(get_json_value "${policy_array[*]}" "steps[$i].icon")
    trigger_list_length=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list.length")

    # If there's a value in the variable, update running swiftDialog
    # if [[ -n "$listitem" ]]; then dialog_update "listitem: $listitem: wait"; fi
    if [[ -n "$listitem" ]]; then dialog_update "listitem: index: $i, status: wait"; fi
    if [[ -n "$icon" ]]; then dialog_update "icon: $icon"; fi
    if [[ -n "$trigger_list_length" ]]; then
        for (( j=0; j<trigger_list_length; j++ )); do
            # Setting variables within the trigger_list
            trigger=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list[$j].trigger")
            path=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list[$j].path")

                $trigger
        done
    fi
    if [[ -n "$listitem" ]]; then dialog_update "listitem: index: $i, status: success"; fi
done

dialog_update "title: $dialog_title_complete"
dialog_update "progresstext: $dialog_status_complete"
dialog_update "button1: enable"
dialog_update "--message: All finished."

#########################################################################################
# Script Cleanup
#########################################################################################
cleanup_stuff

exit 0
exit 1