#!/bin/sh
searchstr="TTRasterizer: Type42"
replacestr="TTRasterizer: None"
if [ $UID -eq 0 ]; then
	echo Starting
else
	echo Root required, try sudo
	exit 1
fi
count=0
for filename in /etc/cups/ppd/*; do
	/usr/bin/grep -q "$searchstr" $filename
	if [ $? -eq 0 ]; then
		/usr/bin/sed -i '' -e "s/$searchstr/$replacestr/" $filename
		echo "+ PPD `/usr/bin/basename $filename`: was fixed"
		count=$((count+1))
	else
		echo "- PPD `/usr/bin/basename $filename`: nothing to fix"
	fi
done
echo Done, number of PPDs fixed: $count
exit 0