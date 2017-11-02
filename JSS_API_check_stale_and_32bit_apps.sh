#!/bin/bash

#https://github.com/bumbletech

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

#check for jq
if [ ! -f /usr/local/bin/jq ]
then
	echo "jq (https://stedolan.github.io/jq/) could not be found. jq is needed to parse iTunes API results. Please install jq and try again."
	echo "If you use Homebrew, run 'brew install jq'."
	echo "Exiting..."
	exit 1
fi

#set the path for the JSS to check
JSSapiPath="${JSSurl}/JSSResource/mobiledeviceapplications"

#set temp location for the xml file
xml_file=/tmp/jss_apps.xml

#get list of bundleIDs for JSS apps
curl -s -u $apiReadOnlyUser:"$apiReadOnlyPass" $JSSapiPath | xpath '//mobile_device_applications/mobile_device_application' 2>&1 | awk -F'<mobile_device_application>|</mobile_device_application>' '{print $2}' | tail -n +3 > $xml_file

function write_app_csv () {

#write csv header
echo "status,jss_id,bundleid,jss_url,itunes_lastknown_url"

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
	#since there's no itunes results, grab the last known URL from the JSS.
	itunes_lastknown_url_raw=`curl -s -u $apiReadOnlyUser:"$apiReadOnlyPass" $JSSapiPath/id/$id | xpath '//mobile_device_application/general/itunes_store_url' 2>&1 | awk -F'<itunes_store_url>|</itunes_store_url>' '{print $2}' | tail -n +3`
	#XML can't deal with "&". replace the escape text.
	itunes_lastknown_url="${itunes_lastknown_url_raw/&amp;/&}"
	itunesAdamId=`echo $itunes_lastknown_url | sed -e 's/.*\/id\(.*\)?.*/\1/'`
	itunesAdamIdQuoted=\"$itunesAdamId\"
	
	#define itunes api lookup path with bundleID from JSS
	itunes_api_url="https://uclient-api.itunes.apple.com/WebObjects/MZStorePlatform.woa/wa/lookup?version=2&id=${itunesAdamId}&p=mdm-lockup&caller=MDM&platform=itunes&cc=us&l=en"
	
	#json results from itunes lookup
	#json=`curl -s "$itunes_api_url"`
	itunes_data="/tmp/itunes_data.json"
	curl -s -H "Accept: application/JSON" -X GET "$itunes_api_url" > $itunes_data
	
	
	
	bundleId=`cat /tmp/itunes_data.json | /usr/local/bin/jq -r .results.$itunesAdamIdQuoted.bundleId`
	is32bitOnly=`cat /tmp/itunes_data.json | /usr/local/bin/jq -r .results.$itunesAdamIdQuoted.is32bitOnly`
	
	# echo "BundleID - $bundleId - $app_bundle_id"
# 	echo "32Bit - $is32bitOnly"
  
  	#check if app's bundleID matches what's on the JSS. If it's blank, there's no record on the iTunes store.
  	if [[ $app_bundle_id != $bundleId ]]; then
  		jss_app_url="${JSSurl}/mobileDeviceApps.html?id=${id}&o=r&nav="
  		#since there's no itunes results, grab the last known URL from the JSS.
		itunes_lastknown_url_raw=`curl -s -u $apiReadOnlyUser:"$apiReadOnlyPass" $JSSapiPath/id/$id | xpath '//mobile_device_application/general/itunes_store_url' 2>&1 | awk -F'<itunes_store_url>|</itunes_store_url>' '{print $2}' | tail -n +3`
  		#XML can't deal with "&". replace the escape text.
		itunes_lastknown_url="${itunes_lastknown_url_raw/&amp;/&}"
  		echo "NO_LONGER_AVAILABLE,$id,$app_bundle_id,$jss_app_url,$itunes_lastknown_url"
  	elif [[ $is32bitOnly == true ]]; then
  		jss_app_url="${JSSurl}/mobileDeviceApps.html?id=${id}&o=r&nav="
  		#since there's no itunes results, grab the last known URL from the JSS.
		itunes_lastknown_url_raw=`curl -s -u $apiReadOnlyUser:"$apiReadOnlyPass" $JSSapiPath/id/$id | xpath '//mobile_device_application/general/itunes_store_url' 2>&1 | awk -F'<itunes_store_url>|</itunes_store_url>' '{print $2}' | tail -n +3`
  		#XML can't deal with "&". replace the escape text.
		itunes_lastknown_url="${itunes_lastknown_url_raw/&amp;/&}"
  		echo "NOT_32BIT,$id,$app_bundle_id,$jss_app_url,$itunes_lastknown_url"
  	fi
  	
  	rm $itunes_data
  	
	index=$[$index+1]
done < $xml_file

}

echo "This may take a while depending on the number of apps in your jss"
echo "Checking apps... please wait..."

#Write a CSV to the desktop with the stale apps
write_app_csv > ~/Desktop/jss_stale_apps.csv

echo ""
echo "All done!"
echo "CSV is at ~/Desktop/jss_stale_apps.csv"
