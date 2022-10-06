#!/bin/bash

#MH 08082022

TempAdminUser= "tempadmin"
TempAdminPassword= "2VMyCTBL"
OldAdmin= "ladmin"
NewAdminPassword= "newpassword"

#create tempadmin user with correct privileges
dscl . -create /Users/$TempAdminUser IsHidden 1
dscl . -create /Users/$TempAdminUser UserShell /bin/bash
dscl . -create /Users/$TempAdminUser RealName “Temp Admin”
dscl . -create /Users/$TempAdminUser UniqueID 993
dscl . -create /Users/$TempAdminUser PrimaryGroupID 20
dscl . -create /Users/$TempAdminUser NFSHomeDirectory /Local/Users/$TempAdminUser
dscl . -passwd /Users/$TempAdminUser $TempAdminPassword
dscl . -append /Groups/admin GroupMembership $TempAdminUser
echo "temp admin created"

#Reset password for old admin with temp admin
sysadminctl -adminUser $TempAdminUser -adminPassword $TempAdminPassword -resetPasswordFor $OldAdmin -newPassword $NewAdminPassword
echo "reset old admin password with temp admin"

#delete temp admin
dscl . -delete /Users/$TempAdminUser
rm -rf /Users/$TempAdminUser
echo "deleted temp admin user"
exit 0