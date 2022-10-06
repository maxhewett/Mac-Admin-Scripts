#!/bin/sh
######################################
#     JSS Decommissioning Script     #
#        Max Hewett 06/10/22         #
#             Cyclone                #
######################################

### Variables ###
adminUser="admin"
adminPass="password"
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//')
serial=$(system_profiler SPHardwareDataType | grep 'Serial Number (system)' | awk '{print $NF}')
JamfID=`curl -H "Accept: text/xml" -sfku "${4}:${5}" "${jssURL}/JSSResource/computers/serialnumber/${JAMF_SERIAL}/subset/general" | xpath -e '/computer/general/id/text()'`
#################
echo "$JamfID -  JSS Computer ID"
echo "$jssURL - JSS URL"
## Printer Removal ##

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
echo "reset CUPS"


## Remove apps ##

    #Lego EV3
    rm -rf /Applications/EV3\ Classroom.app
    echo "removed Lego EV3 app"

    #Zoom
    rm -rf /Applications/zoom.us.app
    rm -rf /Library/LaunchDaemons/us.zoom.ZoomDaemon.plist
    echo "removed Zoom app"

    #Scratch 3/Scratch Link
    rm -rf /Applications/Scratch\ 3.app
    rm -rf /Applications/Scratch\ Link.app
    echo "removed Scratch apps"

    #SimpleMind
    rm -rf /Applications/SimpleMind.app
    echo "removed Simplemind app"

    #Remove Papercut
    rm -rf /Applications/PCClient.app
    echo "removed Papercut client"

    #Remove Up Studio
    rm -rf /Applications/Up\ Studio.app
    echo "removed Up Studio"

    #Remove Janison Replay
    rm -rf /Applications/Janison\ Replay.app
    rm /Users/$loggedInUser/Desktop/Janison\ Replay
    echo "removed Up Janison Replay"


## Remove Munki Launchagents etc. ##
    rm -rf /Applications/Managed\ Software\ Centre.app
    rm -Rf /usr/local/munki
    rm -Rf /usr/local/munkireport

    rm -Rf /Library/Preferences/ManagedInstalls.plist

    rm -Rf /Library/LaunchDaemons/com.googlecode.munki*
    rm -Rf /Library/LaunchDaemons/com.github.munkireport*
    echo "removed munki remnants"


## Remove Local Admin ##

# Capture the user password into a variable
function GetPassword ()
{
USERPASSWORD=$(/usr/bin/osascript << EOF
    activate
    display dialog "Enter the password for $loggedInUser." default answer "password" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
    set UserPassword to text returned of result
EOF)
}
# Make sure if the password is typed incorrectly & prompted for again, it is stored in both variables
function mergePasswords ()
{
if [$USERPASSWORD != $USERPASSWORD2 ]; then
    echo "passwords the same already"
else
    USERPASSWORD="$USERPASSWORD2"
    echo "fixed passwords"
fi

elevateUser
}

# Capture the user password into a variable (again)
function GetPasswordifFailed ()
{
USERPASSWORD2=$(/usr/bin/osascript << EOF
    activate
    display dialog "Incorrect password for $loggedInUser. Please try again" default answer "$USERPASSWORD" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
    set UserPassword to text returned of result
EOF)
mergePasswords
}

# Make student user an admin
function elevateUser ()
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
}

#Add Secure Token to local user
function AddSecureToken ()
{
    echo "adding securetoken to $loggedInUser..."
    if [[ $(sysadminctl -adminUser $adminUser -adminPassword $adminPass -secureTokenOn $loggedInUser -password $USERPASSWORD 2>&1) != *"- Done!"* ]] ; then
        echo "admin password incorrect, re-prompting user"
        GetPasswordifFailed
    else
        echo "securetoken added! Confirming with sysadminctl..."
        sysadminctl -secureTokenStatus $loggedInUser
        echo "updating preboot to allow student to unlock disk"
        diskutil apfs updatepreboot
        MoveSecureToken
    fi
}

#Remove Secure Token from ladmin
function MoveSecureToken ()
{
    echo "removing securetoken from $adminUser..."
    if [[ $(sysadminctl -adminUser $loggedInUser -adminPassword $USERPASSWORD -secureTokenOff $adminUser -password $adminPass 2>&1) != *"- Done!"* ]] ; then
        echo "admin password incorrect, re-prompting user"
        GetPasswordifFailed
    else
        echo "securetoken removed! Confirming with sysadminctl..."
        sysadminctl -secureTokenStatus $adminUser
        echo "updating preboot to allow student to unlock disk"
        diskutil apfs updatepreboot
    fi
}

#remove ladmin
function removeLadmin ()
{
    # Check if our admin has a Secure Token
    if [[ $("/usr/sbin/sysadminctl" -secureTokenStatus $adminUser 2>&1) =~ "ENABLED" ]]; then
        adminToken="true"
        sudo dscl . create /Users/ladmin IsHidden 1
        echo "ladmin has securetoken, cannot be deleted. User hidden instead."
        $(/usr/bin/osascript << EOF
        activate
        display alert "Could not remove $adminUser. Please bring your laptop to IT to finish the clearance process." with title "Error" with icon caution
    EOF)
    else
        adminToken="false"
        /usr/bin/dscl . -delete /Users/ladmin
        rm -rf /Users/ladmin
        echo "ladmin has no securetoken and has been deleted."
    fi

}

#grab password
GetPassword

#elevate user, then move securetoken
elevateUser
        
#remote ladmin
removeLadmin

## Remove Mac from Jamf Pro Server

echo "Removing Mac from Jamf Pro Server..."
if curl -s -k -u "${4}:${5}" "${jssURL}/JSSResource/computers/id/${JamfID}" -X DELETE ; then
    echo "Successfully removed Mac from Jamf Pro Server."
else
    echo "Failed to remove Mac from Jamf Pro Server, Remove manually"
    exit 1
fi

## Remove jamf binary & unenroll ##
jamf -removeMdmProfile
jamf -removeFramework
echo "removed jamf binary"

exit 0