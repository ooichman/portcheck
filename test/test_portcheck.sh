#!/bin/bash

   if [[ -z ${MY_URL} ]]; then
		echo "the variable MY_URL is not defined"
		exit
   fi

   if [[ -z ${REMOTE_HOST} ]]; then
		echo "the variable REMOTE_URL is not defined"
		exit
   fi

   if [[ -z ${DST_PORT} ]]; then
   	echo "The variable DST_PORT is not defined"
   	exit
   fi

		JSONstring=$( jq -n \
			--arg ru "${REMOTE_HOST}" \
			--arg rp "${DST_PORT}" \
			'{"port": $rp ,"target": $ru , "protocol": "tcp"}' )

      
      curl -s -H "Content-type: application/json" -X POST -d "$JSONstring" $MY_URL
