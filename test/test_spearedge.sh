#!/bin/bash

usage(){
    echo "Usage: $0 [ -l ] || -u <URL> -p <Protocol> -n <Port Number> -r <remote host> -h <OpenShift Hostname>"
}

   LIST_HOST=0;

   while getopts ":lh:u:p:n:r:" o; do

      case "${o}" in
          h)
            OCP_HOSTNAME=${OPTARG}
           ;;
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
          l)
              LIST_HOST=1
          ;;
          *)
              usage
          ;;
      esac
   done

   if [[ ${LIST_HOST} -eq 1 ]]; then
         if [[ ! -z ${MY_URL} ]]; then
              curl -s -H "Content-type: application/json" -X GET $MY_URL/listnodes
              exit 0
         else
              echo "You need to use -l with the -u argument"
              exit 1
         fi
   fi

   if [[ -z ${MY_URL} ]]; then
		echo "the variable MY_URL is not defined or the argument '-u' was not set"
                usage
		exit 1
   fi

   if [[ -z ${REMOTE_HOST} ]]; then
		echo "the variable REMOTE_HOST is not defined or the argument '-u' was not set "
                usage
		exit 1
   fi

   if [[ -z ${DST_PORT} ]]; then
   	        echo "The variable DST_PORT is not defined"
                usage
   	        exit 1
   fi

   if [[ -z ${REMOTE_PROTO} ]]; then

	        echo "The Variable REMOTE_PROTO is not definded"
                usage
 	        exit 1
   fi

   if [[ -z ${OCP_HOSTNAME} ]]; then
		echo "the variable OCP_HOSTNAME is not defined"
                usage
		exit 1
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
