#!/bin/bash

# Unless your users are imported from Apple Classroom, the teacher's Classroom app
# will default to displaying the username--not the most helpful.
# This script lets you up update that info with a CSV containing columns for
# username, fullname, and email.

#Edit this line for your JSS
apiPath="https://YOURJSSURLHERE:8443/JSSResource" #MODIFY THIS LINE


###############################
# DO NOT EDIT BELOW THIS LINE #
###############################


echo "Please enter your JSS username:"
read jssUser

echo "Please enter your JSS password:"
read -s apiPassword

#Create counter index for going through the CSV line by line
index="1"

#Get the path for CSV of names and attributes
echo "Please drag and drop your CSV into this window and press enter."
read file

#Setup needed for parsing the CSV correctly
INPUT="$file"
OLDIFS=$IFS
IFS=","
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
#define the columns of the CSV (everthing after "while read" is a column
while read username fullname email
#loop through the CSV one line at a time
do


#setup the data for the XML file for the PUT Request
    echo "<user>
  <roster_managed_apple_id></roster_managed_apple_id>
  <roster_name>$fullname</roster_name>
  <roster_source>MDM</roster_source>
  <roster_source_system_identifier/>
  <roster_unique_identifier/>
  <roster_passcode_type/>
</user>" > "/tmp/blank_location.xml"
    
    #do the put request
    curl -X PUT -H "Accept: application/xml" -H "Content-type: application/xml" -k -u ${jssUser}:${apiPassword} -T /tmp/blank_location.xml ${apiPath}/users/name/$username
    index=$[$index+1]
#stop the loop
done < $file

#Clean up temp XML
rm /tmp/blank_location.xml

echo ""
echo "All lines complete!"

exit 0
