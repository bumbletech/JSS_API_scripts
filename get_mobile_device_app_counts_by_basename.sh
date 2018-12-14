#!/bin/bash

####Change these variables for your enviornment####
JSSurl="https://YOUR.JSS:8443"
apiReadOnlyUser=user
apiReadOnlyPass='pass'


###############################################
### Don't edit past this line. Or whatever. ###
###############################################

#check to see if variables have been changed
if [ "$JSSurl" == "https://YOUR.JSS:8443" ] || [ "$apiReadOnlyUser" == "user" ] || [ "$apiReadOnlyPass" == "pass" ]; then
	echo "One of the variables needed for your JSS and accounts is set to the default. Open this script in a text editor and check the variables for JSSurl, apiReadOnlyUser & apiReadOnlyPass and try again."
	echo "Exiting..."
	exit 1
fi


#set the path for the JSS to check
apiPath="${JSSurl}/JSSResource/mobiledevices/name/"

#Asks for the base name of the iPad group you're wanting to check app counts on
echo ""
echo "Please enter the basename for the iPads you'd like to look up"
echo "(Make sure to include any separators between your basename and the device's number. If a space separates your basename from the device number use '%20' instead at the end of your basename.)"
read baseName

#ask how many ipads are in the cart so it knows where to stop because I didn't write this all that well
echo ""
echo "How many iPads are in the cart?"
echo "(Script assumes number sequences like 01, 02, 03... Enter at least '10' for double digits to work correctly)"
read END


echo ""
echo "Let me look those up for you..."

for i in $(seq -w 01 $END)
    do
    individualDeviceName="$baseName$i"
    #replaces variables in the name with "%20"
    curlDeviceName=${individualDeviceName// /%20}
    appcount=`curl -k -s -u $apiReadOnlyUser:"$apiReadOnlyPass" -H "Accept: application/xml" $apiPath$curlDeviceName/subset/applications | /usr/bin/awk -F'<size>|</size>' '{print $2}'`    
    if [ "$appcount" == "" ]
        then
            echo "$individualDeviceName: I don't think this iPad exists, man."
        else
            echo "$individualDeviceName: $appcount apps"  
    fi

done
