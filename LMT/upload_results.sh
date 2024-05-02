#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2017. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#################################################################################


TOOL_PATH=`dirname "$0"`
CURR_DIR=`pwd`
cd "${TOOL_PATH}"
if [ `echo "$0" | grep "pack_and_upload_results_CRON.sh" | wc -l` -eq 1 ]; then
    cd ".."
fi
if [ `echo "$0" | grep "run_sw_and_upload_CRON.sh" | wc -l` -eq 1 ]; then
    cd ".."
fi
FULL_TOOL_PATH=`pwd`
cd "${CURR_DIR}"
WORK_DIR="${FULL_TOOL_PATH}/work"

. "${FULL_TOOL_PATH}/bin/tools.sh"

setGrepCmd
setupConfigParameters

cd "$FULL_TOOL_PATH"

FILE_SIZE_MAX="104857600" #100MB
#If vmm tool detected increase size by 10 times
detectVMMTool
if [ "$VMM_TOOL_INSTALLED" = true ];
	then
		FILE_SIZE_MAX=`expr $FILE_SIZE_MAX \* 10`
fi
FILE_SIZE_MB=`expr $FILE_SIZE_MAX / 1048576`

FILE_NAME_REGEX='^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-.*\.tar\.gz'
LAST_EC=0

#Check if DATASOURCE_NAME is defined add DATASOURCE_NAME parameter to the request
if [ -z "$DATASOURCE_NAME" ]; then
		DATASOURCE_DEFINITION=""
	else
		DATASOURCE_DEFINITION="&&datasource_name=$DATASOURCE_NAME"
fi


getTSUTC
updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_UPLOAD_RESULTS_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}" $TSUTC

#Check if upload parameters are defined
if [ -z "$LMT_SERVER_URL" -o -z "$LMT_SERVER_API_TOKEN" ];
	then
		printAndLogTxt "The following upload parameters must be defined: LMT_SERVER_URL, LMT_SERVER_API_TOKEN."
		LAST_EC=1
		
	else		
		#Check if output dir exists
		printAndLogTxt "Checking output directory..."
		if [ -d "$PACKAGE_OUTPUT_DIR" ]
			then
				#Check if output dir not empty
				find $PACKAGE_OUTPUT_DIR/* > /dev/null 2>&1
				OUTPUT_DIR_EMPTY_CHECK=$?
				if [ $OUTPUT_DIR_EMPTY_CHECK -eq 0 ];
					then
						#Upload all packages
						cd "$PACKAGE_OUTPUT_DIR"
						printAndLogTxt "Uploading scan results..."
						UPLOAD_DIR="*"
							for f in $UPLOAD_DIR
								do
									#Check if filename matches pattern
									FILE_SIZE=`wc -c <"$f"`
									FILE_NAME_CHECK=`echo $f | grep -c $FILE_NAME_REGEX`
									if [ $FILE_NAME_CHECK = 1 ]; 
										then
										#Check if filesize max not exceeded
											if [ $FILE_SIZE -le $FILE_SIZE_MAX ]; 
											then
												#Upload file
												printAndLogTxt "Processing the $f file..."
												RUN_CMD="$CURL_PATH $CURL_PARAMETERS -H \"Accept:application/json\" -H \"Token:$LMT_SERVER_API_TOKEN\" -H \"Accept-Language: en-US\" -H \"Content-Type:application/octet-stream\" --data-binary \"@$f\" -X POST \"https://$LMT_SERVER_URL/api/sam/v2/scan_results_upload?filename=$f$DATASOURCE_DEFINITION\""; runLogCMD "${RUN_CMD}"
												logTxt "$CMD_OUTPUT"
												CMD_OUTPUT_CHECK=`echo $CMD_OUTPUT | grep -c success\":true`
												if [ $CMD_OUTPUT_CHECK = 1 ];
												then
													#Update scan status when uploaded correctly
													updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_UPLOAD_RESULTS_LAST_PREFIX}${STAT_LAST_OK_TIME_SUFFIX}" $TSUTC

													#Remove package when uploaded
													RUN_CMD="rm -rf $f"; runLogCMD "${RUN_CMD}"
													printAndLogTxt "The $f file was uploaded and removed."								
												else
													CMD_OUTPUT_CHECK=`echo $CMD_OUTPUT | grep -c success\":false.*datasource_name`
													if [ $CMD_OUTPUT_CHECK = 1 ];
														then
														printAndLogTxt "FAILED. Incorrect value of the DATASOURCE_NAME parameter. Provide a correct value."
														else
														printAndLogTxt "FAILED. For more information, check the log file: $LOG_FILE."
													fi
													LAST_EC=1
												fi
											else
											printAndLogTxt "SKIPPED. The file $f is too large to be imported. The maximum size of a file is $FILE_SIZE_MB MB."
											LAST_EC=1
											fi
										else
									printAndLogTxt "SKIPPED. The file $f has incorrect file name format. Provide a file name in the correct format: <scan_date>-<endpoint_ID>.tar.gz."
									LAST_EC=1
									fi

								done
					else
						printAndLogTxt "Output directory $PACKAGE_OUTPUT_DIR is empty. No files will be uploaded."
						exit 0
				fi

			else
				printAndLogTxt "Output directory $PACKAGE_OUTPUT_DIR was not found. No files will be uploaded."
				exit 0
		fi

fi

updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_UPLOAD_RESULTS_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" $LAST_EC
exit $LAST_EC


