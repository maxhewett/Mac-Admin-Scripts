#!/bin/sh
######################################
#     Find/Remove Printers Script    #
#        Max Hewett 30/08/22         #
#             Cyclone                #
######################################

### Variables ###



#################

## Remove IPP printers ##
for The_Printer1 in  $(lpstat -v | awk '/ipp:/ {print $3}' | rev | cut -c2- | rev); do
echo removing ${The_Printer1}
lpadmin -x ${The_Printer1}
done

## Remove Bonjour printers ##
for The_Printer2 in  $(lpstat -v | awk '/dnssd:/ {print $3}' | rev | cut -c2- | rev); do
echo removing ${The_Printer2}
lpadmin -x ${The_Printer2}
done

## Remove Incorrectly named printers ##
for The_Printer3 in  $(lpstat -v | awk '/fuji/ {print $3}' | rev | cut -c2- | rev); do
echo removing ${The_Printer3}
lpadmin -x ${The_Printer3}
done
for The_Printer4 in  $(lpstat -v | awk '/exodus/ {print $3}' | rev | cut -c2- | rev); do
echo removing ${The_Printer4}
lpadmin -x ${The_Printer4}
done

echo removed printers
exit 0