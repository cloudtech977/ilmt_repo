#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2017. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#################################################################################

if [ "${FULL_TOOL_PATH}" = "" ]; then
	TOOL_PATH=`dirname "$0"`
	CURR_DIR=`pwd`
	cd "${TOOL_PATH}"
	cd ".."
	FULL_TOOL_PATH=`pwd`
	cd "${CURR_DIR}"
fi

. "${FULL_TOOL_PATH}/bin/tools.sh"

setGrepCmd


# DEFINITION OF FUNCTIONS

runCatalogScan()
{
	if $CATALOG_SCAN_ENABLED; then
		runScan $SW_SCAN_TYPE "$CATALOG_SCAN_NAME" "$STAT_CATALOG_SCAN_LAST_PREFIX" "$CIT_HOME/bin/wscansw -s -c ${FULL_TOOL_PATH}/config/sw_config.xml -i ${CIT_CATALOG_PATH} -o ${WORK_DIR}/catalog_scan.xml -e ${FULL_TOOL_PATH}/logs/catalog_scan_CIT_warnings.log"
	else
		# reset scan status to empty in case it was disabled
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_CATALOG_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" ""
		printAndLogTxt "$CATALOG_SCAN_NAME is disabled and will be skipped."
	fi
}

runIsoTagScan() 
{
	if [ "$ISOTAG_SCAN_ENABLED" = "true" -o "$DOCKER_SCAN_ENABLED" = "true" ]; then

		if $ISOTAG_SCAN_ENABLED; then
			# if ISO tag is enabled (no matter docker scan enabled or not), scan the whole filesystem
			runScan $SW_SCAN_TYPE "$ISOTAG_SCAN_NAME" "$STAT_ISOTAG_SCAN_LAST_PREFIX" "$CIT_HOME/bin/wscanfs -s -c ${FULL_TOOL_PATH}/config/isotag_config.xml -i -o ${WORK_DIR}/isotag_scan.xml"
		else
			# DOCKER_SCAN_ENABLED only, scan only 1 directory produced by docker scan: work/docker_scan/containers
			INC_DIR_PARAM="<IncludeDirectory value=\"${DOCKER_SCAN_DIR_FOR_ISOTAG_SCAN}\"/>"
			RUN_CMD="sed 's#.*ncludeDirectory.*#${INC_DIR_PARAM}#' ${FULL_TOOL_PATH}/config/isotag_config.xml > ${FULL_TOOL_PATH}/config/isotag_config_docker.xml"; runLogCMD "${RUN_CMD}"

			runScan $SW_SCAN_TYPE "$ISOTAG_SCAN_NAME (docker scope only)" "$STAT_ISOTAG_SCAN_LAST_PREFIX" "$CIT_HOME/bin/wscanfs -s -c ${FULL_TOOL_PATH}/config/isotag_config_docker.xml -i -o ${WORK_DIR}/isotag_scan.xml"
		fi

		EC=$?
		if [ $EC -eq 0 ]; then

			RUN_CMD="mkdir -p ${TEMP_DIR}/isotag_scan"; runLogCMD "${RUN_CMD}"

			# post process ISO tag scan results for disconnected scan
			COUNT=1
			RUN_CMD="touch ${TEMP_DIR}/isotag_scan/list.txt"; runLogCMD "${RUN_CMD}"
			grep '<file path="' "${WORK_DIR}/isotag_scan.xml" | cut -d"\"" -f2,2 | sed "s/\\\\/\\\\\\\\/" > "${WORK_DIR}/tmpISO.txt"
			grep_rc=$?
			if [ $grep_rc -ne 0 ]; then
				logTxt "WARNING: ISO tag scan failed: error during parsing scanner results ($grep_rc)"
				updateOperationStats $DS_RC_ISOTAG_COPYING_FAILED "$ISOTAG_SCAN_NAME" "$STAT_ISOTAG_SCAN_LAST_PREFIX" "Checking the ISO-tag scan content failed - return code $grep_rc"
			else
				cat "${WORK_DIR}/tmpISO.txt" |
				{
					while read ISOTAG; do
						ISOTAG=`echo "$ISOTAG" | sed "s/&#9;/$TAB/g" | sed "s/&lt;/</g" | sed "s/&gt;/>/g" | sed "s/&apos;/'/g" | sed "s/&quot;/\"/g" | sed "s/&amp;/\&/g"`
						if [ -f "${ISOTAG}" ]; then
							if [ `cat "${ISOTAG}" | sed s/patch=/delta=/ | grep "delta=\"true\"" | wc -l` -eq 0 ] && [ `cat "${ISOTAG}" | grep "ibm" | wc -l` -ne 0 ]; then
								echo "${ISOTAG}" > ${TEMP_DIR}/isotag_file_tmp
								ISOTAG_TO_COPY=`cat "${TEMP_DIR}/isotag_file_tmp"`
								rm -rf "${TEMP_DIR}/isotag_file_tmp"
								RUN_CMD="cp -f \"${ISOTAG_TO_COPY}\" ${TEMP_DIR}/isotag_scan/${COUNT}"
								runCMDOnly "${RUN_CMD}"
								if [ $? -eq 0 ]; then
									RUN_CMD="echo \"${ISOTAG_TO_COPY}\" >> ${TEMP_DIR}/isotag_scan/list.txt"
									runCMDOnly "${RUN_CMD}"
									touch -t 1601010000 "${TEMP_DIR}/isotag_scan/${COUNT}"
									COUNT=`expr ${COUNT} + 1`
								else
									logTxt "WARNING: Some problem occurred when copying ISOTag file {$ISOTAG}."
								fi
							fi
						else
							logTxt "WARNING: ISOTag file {$ISOTAG} not found."
						fi          
					done
          
					if [ -f "${TEMP_DIR}/isotag_scan/list.txt" ]; then
						touch -t 1601010000 "${TEMP_DIR}/isotag_scan/list.txt"
					fi
          
					# first clean the directory (list.txt and the 1,2,3 etc. files) generated above
					RUN_CMD="rm -f $ISOTAG_DIR/*"; runLogCMD "${RUN_CMD}"
					RUN_CMD="cp ${TEMP_DIR}/isotag_scan/* $ISOTAG_DIR"; runLogCMD "${RUN_CMD}"
          
					if [ $EC -eq 0 ]; then 
						printAndLogTxt "ISO-tag archive creation was successful"
					else
						updateOperationStats $DS_RC_ISOTAG_COPYING_FAILED "$ISOTAG_SCAN_NAME" "$STAT_ISOTAG_SCAN_LAST_PREFIX" "ISO-tag archive creation failed - return code $EC"
					fi
          
				}   
				RUN_CMD="rm -f ${WORK_DIR}/tmpISO.txt"; runLogCMD "${RUN_CMD}"
			fi
		fi
	else
		# reset scan status to empty in case it was disabled
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_ISOTAG_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" ""
		printAndLogTxt "$ISOTAG_SCAN_NAME is disabled and will be skipped."
	fi
}

runSlmTagScan() 
{
	if $SLMTAG_SCAN_ENABLED; then

		runScan $SW_SCAN_TYPE "$SLMTAG_SCAN_NAME" "$STAT_SLMTAG_SCAN_LAST_PREFIX" "$CIT_HOME/bin/wscanfs -s -c ${FULL_TOOL_PATH}/config/slmtag_config.xml -i -o ${WORK_DIR}/slmtag_scan.xml"
		EC=$?

		if [ $EC -eq 0 ]; then

			TMP_SLM_DIR=${TEMP_DIR}/slmtagScan
			
			RUN_CMD="mkdir -p ${TMP_SLM_DIR}"; runLogCMD "${RUN_CMD}"

			# post process SLM tag scan results for disconnected scan
			COUNT=1
			RUN_CMD="touch ${TMP_SLM_DIR}/list.txt"; runLogCMD "${RUN_CMD}"
			
			
			grep "file path" ${WORK_DIR}/slmtag_scan.xml | cut -f2 -d'"' | while read SLMTAG
			do
				SLMTAG=`echo "$SLMTAG" | sed "s/&#9;/$TAB/g" | sed "s/&lt;/</g" | sed "s/&gt;/>/g" | sed "s/&apos;/'/g" | sed "s/&quot;/\"/g" | sed "s/&amp;/\&/g"`
				if [ -f "${SLMTAG}" ]; then
					
					if [ -f "$MARKER_FILE" ]; then
					
						is_newer "$SLMTAG" "$MARKER_FILE"
						RESULT_NEWER=$?
						
					fi
					
					if [ ! -f "$MARKER_FILE" ] || [ $RESULT_NEWER -eq 0 ]; then
						RUN_CMD="cp -f \"${SLMTAG}\" ${TMP_SLM_DIR}/${COUNT}"
						runCMDOnly "${RUN_CMD}"
						if [ $? -eq 0 ]; then
							RUN_CMD="echo \"${SLMTAG}\" >> ${TMP_SLM_DIR}/list.txt"
							runCMDOnly "${RUN_CMD}"
							COUNT=`expr ${COUNT} + 1`
						else
							logTxt "WARNING: Some problem occurred when copying SLMTag file {$SLMTAG}."
						fi
					fi
					
				else
					logTxt "WARNING: SLMTag file {$SLMTAG} not found."
				fi
			done
			
			RUN_CMD="touch $MARKER_FILE_COMPARE"; runLogCMD "${RUN_CMD}"
			# first clean the directory (list.txt and the 1,2,3 etc. files) generated above
			RUN_CMD="rm -f $SLMTAG_DIR/*"; runLogCMD "${RUN_CMD}"
			
			COUNT=`ls $TMP_SLM_DIR | wc -l`
			if [ $COUNT -eq 1 ]; then
				printAndLogTxt "Current SLM-tags were not found"
			else
				RUN_CMD="cp ${TMP_SLM_DIR}/* $SLMTAG_DIR"; runLogCMD "${RUN_CMD}"
				if [ $EC -eq 0 ]; then 
					printAndLogTxt "SLM-tag archive creation was successful"
				else
					updateOperationStats $DS_RC_SLMTAG_COPYING_FAILED "$SLMTAG_SCAN_NAME" "$STAT_SLMTAG_SCAN_LAST_PREFIX" "SLM-tag archive creation failed - return code $EC"
				fi 
			fi
		fi
	else
		# reset scan status to empty in case it was disabled
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SLMTAG_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" ""
		printAndLogTxt "$SLMTAG_SCAN_NAME is disabled and will be skipped."
	fi
}

runPackageScan()
{
	if $PACKAGE_SCAN_ENABLED; then
		runScan $SW_SCAN_TYPE "$PACKAGE_SCAN_NAME" "$STAT_PACKAGE_SCAN_LAST_PREFIX" "$CIT_HOME/bin/wscanvpd -s -c ${FULL_TOOL_PATH}/config/vpd_config.xml -o ${WORK_DIR}/package_scan.xml"
	else
		# reset scan status to empty in case it was disabled
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_PACKAGE_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" ""
		printAndLogTxt "$PACKAGE_SCAN_NAME is disabled and will be skipped."
	fi
}

runDockerScan()
{
# Supported on Linux platforms only
#
# docker scan (which looks for swidtag and swtag files) must be run before ISO tag scan, file system scan and catalog scan so that the files, 
# which are found in containers and copied on local file system, are discovered by CIT scanner
# if ISO tag scan is not activated then after the docker scan, ISO tag scan will run, 
# but only scanning work/docker_scan/containers directory (System z, zCX server case)
# for general solution once docker scan is completed all scans will run and discover software (inventory)

	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		if $DOCKER_SCAN_ENABLED; then
			"${FULL_TOOL_PATH}/bin/run_docker.sh"
		else
			# reset scan status to empty in case it was disabled
			updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_DOCKER_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" ""
			printAndLogTxt "$DOCKER_SCAN_NAME is disabled and will be skipped."
		fi
	fi
}

resetCitCache()
{
	RUN_CMD="$CIT_HOME/bin/wscanfs -reset"; runLogCMD "${RUN_CMD}"
}

updateSwScanStatus()
{
	getTSUTC
	updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SW_SCAN_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}" $TSUTC
	
	# clear overall scan status to 0
	NEW_STATUS=0
	updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SW_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" $NEW_STATUS
	
	# check every parts of SW scan and if any failed (has status 1) then mark the overall status also as 1
	for NAME in ${STAT_SW_SCAN_LAST_ALL_NAMES}; do
		getValueFromYml "${WORK_DIR}/scanner_status.yml" "${NAME}${STAT_LAST_STATUS_SUFFIX}"
		
		if [ "$YML_VAL" != "" ]; then
			if [ $YML_VAL -ne 0 ]; then
				NEW_STATUS=1
				updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SW_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" $NEW_STATUS
			elif [ $YML_VAL -eq 0 ] && [ "$NAME" != "${STAT_SW_SCAN_LAST_PREFIX}" ]; then
				updateValueInYml "${WORK_DIR}/scanner_status.yml" sw_scan_for_upload "true"
			fi
		fi
	done
	
	if [ $NEW_STATUS -eq 0 ]; then
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SW_SCAN_LAST_PREFIX}${STAT_LAST_OK_TIME_SUFFIX}" $TSUTC;
	fi
}

checkIfAnotherScanIsRunning()
{
	ps -eaf | awk '{ s = ""; for (i = 2; i <= NF; i++) s = s $i " "; print s }' > /tmp/tmpps.txt
	if [ `cat /tmp/tmpps.txt | $GREP_CMD 'wscansw|wscanfs|wscanvpd' | wc -l` -gt 0 ]; then
		return 1;
	else
		return 0;
	fi
}

suppressMsgForCronJob

printAndLogTxt "Starting $SW_SCAN_NAME script ($DISCONNECTED_OS $DISCONNECTED_VERSION)"

checkComputerYmlExists
checkCITExecutableExists "wscanfs"

# read and set setup_config.ini parameters
setupConfigParameters
logConfigParameters

isValidLocale $1 || switchLocale
printAndLogTxt "Data seg size: `ulimit -d`"

checkAndRotateLog
prepareDirs

SCAN_RUNNING=0
if [ "$ALLOW_SIMULTANEOUS_SCAN_EXECUTION" = "false" ]; then
	checkIfAnotherScanIsRunning
	SCAN_RUNNING=$?
	if [ $SCAN_RUNNING -eq 1 ]; then
		getTSUTC
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SW_SCAN_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}" $TSUTC
		
		NEW_STATUS=123
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_SW_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" $NEW_STATUS
		
		logTxt "Another $SW_SCAN_NAME is running (error code: $NEW_STATUS), skipping the scan..."
		printTxt "Another $SW_SCAN_NAME is running, skipping the scan..."
		exit $NEW_STATUS
	fi
fi

checkSoftwareCatalog

TEMP_DIR="$FULL_TOOL_PATH/tempdir"
RUN_CMD="rm -rf $TEMP_DIR"; runLogCMD "${RUN_CMD}"
RUN_CMD="mkdir -p ${TEMP_DIR}"; runLogCMD "${RUN_CMD}"

runDockerScan

resetCitCache
runCatalogScan
runIsoTagScan
runSlmTagScan
runPackageScan
resetCitCache

updateSwScanStatus

printAndLogTxt "All scanners of $SW_SCAN_NAME finished"
