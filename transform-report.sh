#!/bin/sh

# Run Postman CLI
postman login --with-api-key $POSTMAN_APIKEY
postman collection run 36576095-daf9328f-eb19-4b50-844f-72c7b12cde42 -r junit 

# Transform
xmlstarlet tr group-by-childfolder.xsl ./postman-cli-reports/*.xml > ./transformed-junit.xml
