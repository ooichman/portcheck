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

   if [[ -z ${OCP_HOSTNAME} ]]; then
		echo "the variable OCP_HOSTNAME is not defined"
		exit
	fi

   if [[ ${MY_URL} ! ~= "/checkport" ]]; then
	MY_URL="${MY_URL}/checkport"
   fi

		JSONstring=$( jq -n \
			--arg ru "${REMOTE_HOST}" \
			--arg oh "${OCP_HOSTNAME}" \
			--arg rp "${DST_PORT}" \
			'{"port": $rp ,"target": $ru , "protocol": "tcp" , "hostname", $oh}' )

      
      curl -s -H "Content-type: application/json" -X POST -d "$JSONstring" $MY_URL
