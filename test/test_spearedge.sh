#!/bin/bash

   if [[ -z ${MY_URL} ]]; then
		echo "the variable MY_URL is not defined"
		exit
   fi

   if [[ -z ${REMOTE_HOST} ]]; then
		echo "the variable REMOTE_HOST is not defined"
		exit
   fi

   if [[ -z ${DST_PORT} ]]; then
   	echo "The variable DST_PORT is not defined"
   	exit
   fi

   if [[ -z ${REMOTE_PROTO} ]]; then

	echo "The Variable REMOTE_PROTO is not definded"
	exit
   fi

   if [[ -z ${OCP_HOSTNAME} ]]; then
		echo "the variable OCP_HOSTNAME is not defined"
		exit
	fi

   if [[ ! ${MY_URL} =~ "/checkport" ]]; then
	MY_URL="${MY_URL}/checkport"
   fi

		JSONstring=$( jq -n \
			--arg ru "${REMOTE_HOST}" \
			--arg oh "${OCP_HOSTNAME}" \
			--arg rp "${DST_PORT}" \
                        --arg pr "${REMOTE_PROTO}" \
			'{"port": $rp ,"target": $ru , "protocol": $pr , "hostname": $oh}' )

 # un commet the following line for debuging 
 #     echo "$JSONstring"
      curl -s -H "Content-type: application/json" -X POST -d "$JSONstring" $MY_URL
