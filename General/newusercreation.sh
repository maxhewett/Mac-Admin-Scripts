#!/bin/sh

#  newusercreation.sh
#
#  OSAScript-based quick device reprovision script
#
#  Created by Max Hewett on 19/10/22.
#
#
#
######################################################################
## Variables
######################################################################

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`

######################################################################
######################################################################
## Prompt User to select user to delete
######################################################################
chooseto_delete="$(osascript -e 'button returned of (display dialog "Do you need to delete an old user?" buttons {"No", "Yes"})')"

if [[ "${chooseto_delete}" == "No" ]]; then
    echo "do not delete"
else
    echo "do delete"
    ##prompt for user to delete
    chosen_user="$(OSASCRIPT_ENV_DELETEABLE_USERS="$(dscl . list /Users | grep -v -e '_' -e 'root' -e 'daemon' -e 'nobody' -e 'administrator' | tail +1)" osascript -e 'set chosen_user to text returned of (choose from list (paragraphs of (system attribute "OSASCRIPT_ENV_DELETEABLE_USERS")) with prompt "The User you would like to delete:" default items {""})')"
    echo "deleting $chosen_user..."
    sudo dscl . -delete /Users/$chosen_user
fi

######################################################################
######################################################################
## Prompt user for new user details
######################################################################
chooseto_create="$(osascript -e 'button returned of (display dialog "Do you need to create a new user?" buttons {"No", "Yes"})')"

if [[ "${chooseto_create}" == "No" ]]; then
    echo "do not create"
else
    echo "do create"
    newuser_User_Name="$(osascript -e 'set newuser_User_Name to text returned of (display dialog "Type the full name of the new user" default answer "Firstname Lastname")')"

    newuser_username="$(osascript -e 'set newuser_username to text returned of (display dialog "Choose a lowercase username" default answer "username")')"

    newuser_password="$(osascript -e 'set newuser_password to text returned of (display dialog "Choose a password for the new user" default answer "password" with hidden answer)')"
    
    newuser_admin="$(osascript -e 'button returned of (display dialog "Should the new user be an admin?" buttons {"No", "Yes"})')"
    
        sudo dscl . -create /Users/$newuser_username
        sudo dscl . -create /Users/$newuser_username UserShell /bin/zsh
        sudo dscl . -create /Users/$newuser_username RealName $newuser_User_Name
        sudo dscl . -passwd /Users/$newuser_username $newuser_password
fi

## create user
if [[ "${newuser_admin}" == "Yes" ]]; then
    echo "new user should be admin"
    sudo dscl . -append /Groups/admin GroupMembership $newuser_username
else
    echo "new user shouldn't be an admin or no new user being created"
fi

##print to console what user details have been created
echo "New user created with name: $newuser_User_Name"
echo "Username: $newuser_username"
##check for weak password
if [[ "${newuser_password}" == *"password"* ]]; then
    echo "password was set to password. Please prompt user to change this"
    weakpassword="yes"
else
    echo "password that isn't password created."
    weakpassword="no"
fi

######################################################################
######################################################################
## Prompt user to select extra apps to install, then run jamf
## policies to install those apps/features.
######################################################################

chosen_apps="$(OSASCRIPT_ENV_EXTRA_APPS="$(echo "app1 app2 app3" | tr ' ' '\n')" osascript -e 'choose from list (paragraphs of (system attribute "OSASCRIPT_ENV_EXTRA_APPS")) with prompt "Additional apps to install:" default items {""} with multiple selections allowed')"

## Install app1 if selected
if [[ "${chosen_apps}" == *"app1"* ]]; then
    echo "app1 is there"
    #jamf policy -trigger policyName
else
    echo "app1 is not there"
fi

## Install app2 if selected
if [[ "${chosen_apps}" == *"app2"* ]]; then
    echo "app2 is there"
    #jamf policy -trigger policyName
else
    echo "app2 is not there"
fi

## Install app3 if selected
if [[ "${chosen_apps}" == *"app3"* ]]; then
    echo "app3 is there"
    #jamf policy -trigger policyName
else
    echo "app3 is not there"
fi
