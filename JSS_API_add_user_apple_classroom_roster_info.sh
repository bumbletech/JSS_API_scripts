#!/bin/bash

# Unless your users are imported from Apple Classroom, the teacher's Classroom app
# will default to displaying the username--not the most helpful.
# This script let's up update that info with a CSV containing columns for
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

#Create counter index
index="1"

#Pull filename for CSV of names and attributes
echo "Please drag and drop your CSV into this window and press enter."
read file

#Loop to add attributes to names
INPUT="$file"
OLDIFS=$IFS
IFS=","
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read username fullname email
do

    echo "<user>
  <roster_managed_apple_id></roster_managed_apple_id>
  <roster_name>$fullname</roster_name>
  <roster_source>MDM</roster_source>
  <roster_source_system_identifier/>
  <roster_unique_identifier/>
  <roster_passcode_type/>
</user>" > "/tmp/blank_location.xml"

    curl -X PUT -H "Accept: application/xml" -H "Content-type: application/xml" -k -u ${jssUser}:${apiPassword} -T /tmp/blank_location.xml ${apiPath}/users/name/$username
    index=$[$index+1]
done < $file

#Clean up temp XML
#rm /tmp/blank_location.xml

echo ""
echo "All lines complete!"

exit 0
