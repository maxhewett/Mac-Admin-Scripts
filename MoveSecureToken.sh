#!/bin/bash

adminUser="admin"
adminPass="password"
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`

function GetPassword ()
{
## Capture the user input into a variable
USERPASSWORD=$(/usr/bin/osascript << EOF
    activate
    display dialog "Enter the password for $loggedInUser." default answer "password" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
    set UserPassword to text returned of result
EOF)
}

function mergePasswords ()
{
if [$USERPASSWORD != $USERPASSWORD2 ]; then
    echo "passwords the same already"
else
    USERPASSWORD="$USERPASSWORD2"
    echo "fixed passwords"
fi
}

function GetPasswordifFailed ()
{
## Capture the user input into a variable
USERPASSWORD2=$(/usr/bin/osascript << EOF
    activate
    display dialog "Incorrect password for $loggedInUser. Please try again" default answer "$USERPASSWORD" with hidden answer with title "Enter Password" with icon POSIX file "/System/Library/CoreServices/Certificate Assistant.app/Contents/Resources/AppIcon.icns"
    set UserPassword to text returned of result
EOF)
mergePasswords
}

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
    MoveSecureToken
    fi
}

function MoveSecureToken ()
{
    echo "removing securetoken from $adminUser..."
    if [[ $(sysadminctl -adminUser $loggedInUser -adminPassword $USERPASSWORD -secureTokenOff $adminUser -password $adminPass 2>&1) != *"- Done!"* ]] ; then
        echo "admin password incorrect, re-prompting user"
        GetPasswordifFailed
    else
        echo "securetoken removed! Confirming with sysadminctl..."
        sysadminctl -secureTokenStatus $adminUser
    fi
}

#grab password
GetPassword

#elevate user, then move securetoken
elevateUser