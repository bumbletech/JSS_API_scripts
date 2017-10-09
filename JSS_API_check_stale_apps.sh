#!/bin/bash

#https://github.com/bumbletech

#Thanks to Jamie Phelps for the JSON parsing.
#http://jxpx777.me/blog/20131217-simple-json-processing-in-shell-scripts.html

####Change these variables for your enviornment####
JSSurl="https://yourjss:8443"
apiReadOnlyUser=youruser
apiReadOnlyPass='yourpass'


###############################################
### Don't edit past this line. Or whatever. ###
###############################################

#check to see if variables have been changed
if [ "$JSSurl" == "https://yourjss:8443" ] || [ "$apiReadOnlyUser" == "user" ] || [ "$apiReadOnlyPass" == "pass" ]; then
	echo "One of the variables needed for your JSS and accounts is set to the default. Open this script in a text editor and check the variables for JSSurl, apiReadOnlyUser & apiReadOnlyPass and try again."
	echo "Exiting..."
	exit 1
fi

#path for json parsing tool
jscPath="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc"

#set the path for the JSS to check
JSSapiPath="${JSSurl}/JSSResource/mobiledeviceapplications"

#set temp location for the xml file
xml_file=/tmp/jss_apps.xml

#get list of bundleIDs for JSS apps
curl -s -u $apiReadOnlyUser:"$apiReadOnlyPass" $JSSapiPath | xpath '//mobile_device_applications/mobile_device_application' 2>&1 | awk -F'<mobile_device_application>|</mobile_device_application>' '{print $2}' | tail -n +3 > $xml_file

function write_app_csv () {

#write csv header
echo "jss_id,bundleid,jss_url"

#loop through each line of the XML out put so both the bundleID and the JSS app ID of an can be worked with
INPUT="$xml_file"
OLDIFS=$IFS
IFS=","
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read xml_string

do
	#set the app info from the JSS
	id=`echo "$xml_string" | awk -F'<id>|</id>' '{print $2}'`
	app_bundle_id=`echo "$xml_string" | awk -F'<bundle_id>|</bundle_id>' '{print $2}'`
	
	#define itunes api lookup path with bundleID from JSS
	itunes_api_url="http://itunes.apple.com/lookup?bundleId=${app_bundle_id}"	
	
	#json results from itunes lookup
	json=`curl -s "$itunes_api_url"`

	bundleId=`$jscPath -e "var json = $json; json['results'].forEach(function(result) { print(result['bundleId']) });"`

  
  	#check if app's bundleID matches what's on the JSS. If it's blank, there's no record on the iTunes store.
  	if [[ $app_bundle_id != $bundleId ]]; then
  		jss_app_url="${JSSurl}/mobileDeviceApps.html?id=${id}&o=r&nav="
  		echo "$id,$app_bundle_id,$jss_app_url" 
  	fi
  	
	index=$[$index+1]
done < $xml_file

}

echo "This may take a while depending on the number of apps in your jss"
echo "Checking apps... please wait..."

#Write a CSV to the desktop with the stale apps
write_app_csv > Desktop/jss_stale_apps.csv

echo ""
echo "All done!"
echo "CSV is at Desktop/jss_stale_apps.csv"

