#!/bin/bash

usage(){
    echo "Usage: $0 -u <URL> -p <Protocol> -n <Port Number> -r <remote host>"
}

   while getopts ":u:p:n:r:" o; do

      case "${o}" in
          u)
             MY_URL=${OPTARG}
           ;;
          r)
             REMOTE_HOST=${OPTARG}
          ;;
          p)
            REMOTE_PROTO=${OPTARG}
          ;;
          n)
            DST_PORT=${OPTARG}
          ;;
          *)
              usage
          ;;
      esac
   done

   if [[ -z ${MY_URL} ]]; then
                usage
		echo "the variable MY_URL is not defined"
		exit
   fi

   if [[ -z ${REMOTE_HOST} ]]; then
                usage
		echo "the variable REMOTE_URL is not defined"
		exit
   fi

   if [[ -z ${REMOTE_PROTO} ]]; then
                usage
                echo "The Variable REMOTE_PROTO is not definded"
                exit
   fi


   if [[ -z ${DST_PORT} ]]; then
                usage
   	        echo "The variable DST_PORT is not defined"
   	        exit
   fi

		JSONstring=$( jq -n \
			--arg ru "${REMOTE_HOST}" \
			--arg rp "${DST_PORT}" \
                        --arg pr "${REMOTE_PROTO}" \
			'{"port": $rp ,"target": $ru , "protocol": $pr}' )

          echo $JSONstring | jq
          curl -sk -H "Content-type: application/json" -X POST -d "$JSONstring" $MY_URL
