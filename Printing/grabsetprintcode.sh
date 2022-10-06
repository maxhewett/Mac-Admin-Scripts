#!/bin/bash
######################################
#      Grab and set Print Code       #
#        Max Hewett 03/10/22         #
#             Cyclone                #
######################################

function askForDeptCode ()
{

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`

PrinterName="Staff_Room_Copier" #Should match the name of the printer in the install script
PrinterLocation="Staff Room" #Should match the location of the printer in the install script

## Capture the user input into a variable
DEPTCODE=$(/usr/bin/osascript << EOF
    activate
    display dialog "Please enter your department code for the printers, seperated by hyphens. (Example: 1-2-3-4)" default answer "0-0-0-0" with icon POSIX file "/Library/Printers/toshiba/Icons/ColorMFP.icns"
    set DeptCode to text returned of result
EOF)

## Check the variable to make sure it's not empty...
if [ "$DEPTCODE" == "" ]; then
    echo "Department code was not entered. Re prompting the user..."
    askForDeptCode
    
else 

#if [[ $DEPTCODE != *"-"* ]]; then
 # echo "No hyphens. Re-prompting user..."
  #askForDeptCode
#else
    echo "Department Code entered was: $DEPTCODE"
fi
  
  
IFS='-' #setting hyphen as delimiter  
read -a strarr <<<"$DEPTCODE" #reading str as an array as tokens separated by IFS  

## Set department code with lpadmin (does not work with 4-digit codes)
#lpadmin -p $PrinterName -L $PrinterLocation -o DeptCode=True -o DCDigit1=${strarr[0]} -o DCDigit2=${strarr[1]} -o DCDigit3=${strarr[2]} -o DCDigit4=${strarr[3]} -o DCDigit5=' '

lpadmin -p $PrinterName -L $PrinterLocation -o DeptCode=True

/usr/libexec/PlistBuddy -c "Set 'Black & White':com.apple.print.preset.settings:com.toshiba.pde.print-mode-ebx.departmentCode ${strarr[0]}${strarr[1]}${strarr[2]}${strarr[3]}" /Users/$loggedInUser/Library/Preferences/com.apple.print.custompresets.plist

/usr/libexec/PlistBuddy -c "Set 'Colour':com.apple.print.preset.settings:com.toshiba.pde.print-mode-ebx.departmentCode ${strarr[0]}${strarr[1]}${strarr[2]}${strarr[3]}" /Users/$loggedInUser/Library/Preferences/com.apple.print.custompresets.plist


echo "set print code as ${strarr[0]}${strarr[1]}${strarr[2]}${strarr[3]} on $PrinterName"
 
}

## Run the function above
askForDeptCode
killall cfprefsd

exit 0