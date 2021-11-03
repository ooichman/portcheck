#!/bin/bash -x

function html_to_post() {    
    echo "Content-type: text/html"
    echo ""
    echo "<!DOCTYPE html>"
    echo "<html><head>"
    echo "<title>portcheck script</title>"
    echo "</head><body>"
    echo "<h1>using POST Method and HTML is forbidden</h1>"
    echo "<p>Using POST Method and HTML is forbidden , Please try POST with 'Application/json' or HTML with GET Method</p>"
    echo "<hr>"
    echo "</body></html>"
}

function response_with_json(){
    echo "Content-type: application/json"
    echo ""
    echo "{\"Result\": \"$1\"}"
}

if [ "$REQUEST_METHOD" = "POST" ]; then

    # The environment variabe $CONTENT_TYPE describes the data-type received
    case "$CONTENT_TYPE" in
    application/json)
        # The environment variabe $CONTENT_LENGTH describes the size of the data
        read -n "$CONTENT_LENGTH" QUERY_STRING_POST        # read datastream# The following lines will prevent XSS and check for valide JSON-Data.
        # But these Symbols need to be encoded somehow before sending to this script
        QUERY_STRING_POST=$(echo "$QUERY_STRING_POST" | sed "s/'//g" | sed 's/\$//g;s/`//g;s/\*//g;s/\\//g' )

        # removes some symbols (like \ * ` $ ') to prevent XSS with Bash and SQL.

        QUERY_STRING_POST=$(echo "$QUERY_STRING_POST" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba') # removes most html declarations to prevent XSS within documents

        JSON=$(echo "$QUERY_STRING_POST" | jq .)
	DST_PORT=$( echo ${JSON} | jq .port)
	DST_TARGET=$( echo ${JSON} | jq .target)

	DST_PORT=$(echo $DST_PORT | sed "s/\"//g")
	DST_PORT=$(echo $DST_PORT | sed "s/\'//g")
	DST_PORT=$(echo $DST_PORT | sed "s/://g")
	
	DST_TARGET=$(echo $DST_TARGET | sed "s/\"//g")
	DST_TARGET=$(echo $DST_TARGET | sed "s/\'//g")
        # json encode - This is a pretty save way to check for valide json codeecho "Content-type: application/json"

	if [[ -z $DST_PORT ]] || [[ -z $DST_TARGET ]]; then
		echo "Port or Target not definded "
	else
nc -vz ${DST_TARGET} ${DST_PORT} <<EOF
quit
EOF
RESULT=$?

	       if [[ $RESULT -eq 0 ]]; then
			response_with_json Success
	       else
        	        response_with_json Failure
		fi
     fi
    ;;

    *)
       html_to_post
        exit 0
    ;;
    esac

elif [ "$REQUEST_METHOD" = "GET" ]; then

   if [[ "$CONTENT_TYPE" =~ "application/json" ]]; then

	echo "${QUERY_STRING}"
   else
   	echo "${QUERY_STRING}"
   fi

fi
