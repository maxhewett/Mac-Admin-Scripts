#!/bin/bash
#########################################
# Convert OD User to Local User Script  #
#         Max Hewett 23/11/22           #
#########################################

### Variables ###
adminUser="ladmin"
adminPass="t@llEarth81"
tempUser="temp"
tempPass="temp"
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
loggedInUserID=`id -u $loggedInUser`
loggedInUserGID=`id -g $loggedInUser`
loggedInUserRealName=$(dscl . -read /Users/$loggedInUser RealName | cut -d':' -f2 | sed 's/^ //g')
debug="true"
#################

### Functions ###
function saveCurrentusertofile () {
echo $loggedInUser > /Users/Shared/storedUser.txt
echo $loggedInUserID > /Users/Shared/storedUserID.txt
echo $loggedInUserGID > /Users/Shared/storedUserGID.txt
echo $loggedInUserRealName > /Users/Shared/storedRealName.txt
echo "current user saved to file"
}
function restartAlert () {
    $(/usr/bin/osascript << EOF
    display dialog "Your Mac will now restart. At the login window, login using the Temporary user, the password is temp." with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
EOF
)
}

### Pre-Flight Stuff ###
if [ -a "/Users/Shared/tempusercreated.txt" ]; then
    #do nothing
    echo "user info already stored"
else
    saveCurrentusertofile
fi
storedUser=`cat /Users/Shared/storedUser.txt`
storedUserID=`cat /Users/Shared/storedUserID.txt`
storedUserGID=`cat /Users/Shared/storedUserGID.txt`
storedUserRealName=`cat /Users/Shared/storedRealName.txt`

function GetPassword ()
{
while true
    USERPASSWORD=$(sudo -u "$loggedInUser" /usr/bin/osascript << EOF
        activate
        display dialog "Enter the password for $storedUser." default answer "" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
        set UserPassword to text returned of result
    EOF
    )
    userPassCheck=$(/usr/bin/dscl /Local/Default -authonly "$storedUser" "$USERPASSWORD")
    if [[ -z "$userPassCheck" ]]; then
        echo "Password correct"
        break
    else
        echo "User Password not set correctly"
    fi
done
}
#################

############# MAIN BODY OF SCRIPT #############

## Create Temp User ##
if [ -a "/Users/Shared/tempusercreated.txt" ]; then
    echo "User has been stored ($storedUser), carrying on with rest of script"
else
    echo "STEP 1"
    sysadminctl -addUser "$tempUser" -password "$tempPass" -fullName "Temporary User" -admin -adminUser "$adminUser" -adminPassword "$adminUser" 2>&1
    #also
    touch /Users/$tempUser/.skipbuddy
    echo "created temporary admin user named $tempUser with password $tempPass."
    echo "current user is $storedRealName, username $storedUser with ID $storedUserID and primary group ID $storedUserGID."
    restartAlert
    touch /Users/Shared/tempusercreated.txt
    exit 0
fi
## Created Temp User ##

##### LOG OUT SHOULD HAPPEN HERE #####

## Get old user password, delete old user from directory, create new user ##
if [ -a "/Users/Shared/tempusercreated.txt" ]; then
    echo "STEP 2"
    GetPassword
    echo "Got password from user prompt, password set to $USERPASSWORD"
    #create new standard user with same home directory as mobile account
    sysadminctl -addUser "$storedUser" -password "$USERPASSWORD" -fullName "$storedUserRealName" -home "/Users/$storedUser" -admin -adminUser "$tempUser" -adminPassword "$tempPass" 2>&1
    /usr/sbin/sysadminctl -adminUser "${tempUser}" -adminPassword "${tempPass}" -resetPasswordFor "${storedUser}" -newPassword "${USERPASSWORD}"
    touch /Users/"$storedUser"/.skipbuddy
    echo "user $storedUser re-created"
    createdUserUID=$(dscl /Local/Default -read /Users/"$storedUser" UniqueID | cut -d' ' -f2)
fi
## grabbed password, deleted, recreated ##

## Set home folder permissions ##
if [ -a "/Users/Shared/tempusercreated.txt" ]; then
    echo "STEP 3"
    #change ownership on home folders to new user
    /usr/sbin/chown -R "${createdUserUID}":20 /Users/"${storedUser}"
    echo "ownership changed on /Users/$storedUser to ID $createdUserUID"
    # delete temp user
    dscl . -delete /Users/$tempUser
    rm -rf /Users/$tempUser
    echo "temp user deleted, restarting in 30s"
    sleep 30
    exit 0
fi