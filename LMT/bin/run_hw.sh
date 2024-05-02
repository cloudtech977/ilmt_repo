#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2017. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##################################################################################

if [ "${FULL_TOOL_PATH}" = "" ]; then
	TOOL_PATH=`dirname "$0"`
	CURR_DIR=`pwd`
	cd "${TOOL_PATH}"
	cd ".."
	FULL_TOOL_PATH=`pwd`
	cd "${CURR_DIR}"
fi 

. "${FULL_TOOL_PATH}"/bin/tools.sh

setGrepCmd


# DEFINITION OF FUNCTIONS

generateUUID() {
	local N B T R C
	for N in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
		C=`hexdump -n 2 -e '/2 "%u"' /dev/urandom`
		B=`expr $C % 255`
		R=$R`printf '%02x' $B`
		for T in 3 5 7 9; do
			if [ $T -eq $N ]; then
				R="$R-"
				break
			fi
		done
	done
	echo $R
}

setupTemplates()
{
	RUN_CMD="cp \"${FULL_TOOL_PATH}\"/config/computer_TEMPLATE.yml \"$WORK_DIR\"/computer.yml"; runLogCMD "${RUN_CMD}"
}

getIdsAndTimestamp()
{
	printAndLogTxt "User info: `id`"

	HOSTNAME_NAME=`hostname`
	HOSTNAME_INFO=`echo ${HOSTNAME_NAME} | sed 's/^[ ]*//;s/[ ]*$//'`
	SYSTEM_INFO=`uname -a`
	printAndLogTxt "System info (uname): $SYSTEM_INFO"

	TIME_SHORT=`date -u +%Y%m%d%H%M`

	SEC_2016_01_01="1451606400"
	AVG_SEC_YEAR="31557600"
	SEC_DAY="86400"
	SEC_HOUR="3600"
	SEC_MIN="60"
	DATE_DAYS=`date -u +%j`
	DATE_YEAR=`date -u +%Y`
	DATE_HOUR=`date -u +%H`
	DATE_MIN=`date -u +%M`
	DATE_SEC=`date -u +%S`

	SECONDS_FROM_1970=`expr ${SEC_2016_01_01} + \( ${DATE_YEAR} - 2016 \) \* ${AVG_SEC_YEAR} + \( ${DATE_DAYS} - 1 \) \* ${SEC_DAY} + ${DATE_HOUR} \* ${SEC_HOUR} + ${DATE_MIN} \* ${SEC_MIN} + ${DATE_SEC}`
}

refreshComputerYml() {
	printAndLogTxt "Preparing computer.yml file..."
		
	FILE_SYSIDS="$WORK_DIR"/sysIDs.txt
	FILE_SYSIDS_CIT_COMP="$WORK_DIR"/sysIDs_CIT_Compid.xml
	FILE_SYSIDS_CIT_OS="$WORK_DIR"/sysIDs_CIT_OS.xml
	FILE_SYSIDS_CIT_IP="$WORK_DIR"/sysIDs_CIT_IP.xml	
	
	RUN_CMD="echo \"hostname: $HOSTNAME_INFO\" > \"${FILE_SYSIDS}\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"uname : $SYSTEM_INFO\" >> \"$FILE_SYSIDS\""; runLogCMD "${RUN_CMD}"

	RUN_CMD="sed -n \"/<ComponentID/,/<\/ComponentID>/p\" \"$HW_SCAN_FILENAME_FULL\" > \"$FILE_SYSIDS_CIT_COMP\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="sed -n \"/<OperatingSystem/,/<\/OperatingSystem>/p\" \"$HW_SCAN_FILENAME_FULL\" > \"$FILE_SYSIDS_CIT_OS\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="sed -n \"/<IPAddress/,/<\/IPAddress>/p\" \"$HW_SCAN_FILENAME_FULL\" > \"$FILE_SYSIDS_CIT_IP\""; runLogCMD "${RUN_CMD}"

	if [ "$HOSTNAME_INFO" = "" ]; then
	HOSTNAME_INFO=`grep Hostname "${FILE_SYSIDS_CIT_IP}" | cut -f2 -d ">" | cut -f1 -d "<" | head -1`
	fi
	if [ "${HOSTNAME_INFO}" = "" ]; then printAndLogTxtExit "Getting hostname info failed"; fi

	ID_REG_ENABLED=`echo $ENDPOINT_ID_REGENERATION_ENABLED | grep -i true | wc -l`
	if [ $ID_REG_ENABLED -eq 1 ]; then
		if [ -f "${FULL_TOOL_PATH}/config/hostname.txt" ];then
			PREVIOUS_HOSTNAME=`cat "${FULL_TOOL_PATH}/config/hostname.txt"`
		else
			PREVIOUS_HOSTNAME="NOT_SET_AT_ALL"
		fi
	fi

	if [ -f "${FULL_TOOL_PATH}/config/endpoint_id.txt" ] && { [ $ID_REG_ENABLED -eq 0 ] || { [ $ID_REG_ENABLED -eq 1 ] && [ "${HOSTNAME_INFO}" = "${PREVIOUS_HOSTNAME}" ]; } } then
		ENDPOINT_ID=`cat "${FULL_TOOL_PATH}/config/endpoint_id.txt"`
		printAndLogTxt "Using already generated Endpoint ID: ${ENDPOINT_ID}"
	else
		ENDPOINT_ID="${HOSTNAME_INFO}-${SECONDS_FROM_1970}"
		RUN_CMD="echo ${ENDPOINT_ID} > ${FULL_TOOL_PATH}/config/endpoint_id.txt"; runLogCMD "${RUN_CMD}"
		RUN_CMD="echo ${HOSTNAME_INFO} > ${FULL_TOOL_PATH}/config/hostname.txt"; runLogCMD "${RUN_CMD}"

		if [ "$ID_REG_ENABLED" -eq 1 ]; then
			printAndLogTxt "Generated new Endpoint ID: ${ENDPOINT_ID} as current hostname is ${HOSTNAME_INFO} and previous was ${PREVIOUS_HOSTNAME}"

			ARCHIVE_DIR="${WORK_DIR}/archive"
			if [ -d ${ARCHIVE_DIR} ]; then
				RUN_CMD="rm -rf ${WORK_DIR}/archive"; runLogCMD "${RUN_CMD}"
			fi

			UNIQUE_SCANS_DIR="${WORK_DIR}/hw_scans_unique"
			if [ -d ${UNIQUE_SCANS_DIR} ]; then
				RUN_CMD="rm -rf ${WORK_DIR}/hw_scans_unique"; runLogCMD "${RUN_CMD}"
			fi 
			
			# remove previous packages (with old hostname) from output dir
			if [ -d ${PACKAGE_OUTPUT_DIR} ]; then
				RUN_CMD="rm -f ${PACKAGE_OUTPUT_DIR}/*"; runLogCMD "${RUN_CMD}"
			fi
		fi
	fi

	getHWScanData Name "$FILE_SYSIDS_CIT_OS"
	HWSCAN_OS_NAME=$CMD_OUTPUT
	getHWScanData Type "$FILE_SYSIDS_CIT_OS"
	HWSCAN_OS_TYPE=$CMD_OUTPUT
	getHWScanData OSArch "$FILE_SYSIDS_CIT_OS"
	HWSCAN_OS_ARCH=$CMD_OUTPUT
	getHWScanData OSKernelMode "$FILE_SYSIDS_CIT_OS"
	HWSCAN_OS_KERNEL=$CMD_OUTPUT

	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		OPERATING_SYSTEM=`echo \"Operating System: ${HWSCAN_OS_TYPE} ${HWSCAN_OS_NAME} ${HWSCAN_OS_ARCH} ${HWSCAN_OS_KERNEL}\" | sed -e 's/  */ /g'`
	elif [ "$OS_NAME" = "$OS_NAME_AIX" -o "$OS_NAME" = "$OS_NAME_SOLARIS" ]; then
		getHWScanData MajorVersion "$FILE_SYSIDS_CIT_OS"
		HWSCAN_OS_VER=$CMD_OUTPUT
		getHWScanData MinorVersion "$FILE_SYSIDS_CIT_OS"
		HWSCAN_OS_REL=$CMD_OUTPUT
		getHWScanData SubVersion "$FILE_SYSIDS_CIT_OS"
		HWSCAN_OS_SUB=$CMD_OUTPUT
		OPERATING_SYSTEM=`echo "Operating System: ${HWSCAN_OS_NAME} ${HWSCAN_OS_VER}.${HWSCAN_OS_REL} \(${HWSCAN_OS_SUB}\) ${HWSCAN_OS_ARCH} ${HWSCAN_OS_KERNEL}" | sed -e 's/  */ /g'`
	fi
	
	if [ "${OPERATING_SYSTEM}" = "" ]; then printAndLogTxtExit "Getting operating system failed"; fi

	# IP address of the computer, used for identification. For multiple IPs, place each address on a new line that starts with a space.
	getHWScanDataAllInstances "Address IsKey" "$FILE_SYSIDS_CIT_IP"
	IP_ADDR=$CMD_OUTPUT
	if [ "${IP_ADDR}" = "" ]; then printAndLogTxtExit "IP Address gathering failed"; fi

	RUN_CMD="echo endpointID: $ENDPOINT_ID > \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo Agent Version: $DISCONNECTED_VERSION >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo Catalog Version: ${CATALOG_VER} >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo ${OPERATING_SYSTEM} >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo DNS Name: ${HOSTNAME_INFO} >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo Computer Name: ${HOSTNAME_INFO} >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"IP Address: ${IP_ADDR}\" >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		RUN_CMD="echo vmmanagerPresent: ${VMM_TOOL_INSTALLED} >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
		RUN_CMD="echo vtechEnabled: ${VIRTUALIZATION_HOST_SCAN_ENABLED} >> \"$WORK_DIR/computer_tmp.yml\""; runLogCMD "${RUN_CMD}"
	fi

	RUN_CMD="mv -f \"$WORK_DIR/computer_tmp.yml\" \"$WORK_DIR/computer.yml\""; runLogCMD "${RUN_CMD}"	
	printAndLogTxt "Preparing/refreshing computer.yml finished"
}

removeIpAddressAndEmptyLines() {             
	RUN_CMD="sed -e \"/<IPAddress/,/<\/IPAddress>/d\" \"$HW_SCAN_FILENAME_FULL\" | sed -e \"/^$/d\" > \"$HW_SCAN_FILENAME_FULL_TMP\""; runLogCMD "${RUN_CMD}"
	RUN_CMD="mv -f \"$HW_SCAN_FILENAME_FULL_TMP\" \"$HW_SCAN_FILENAME_FULL\""; runLogCMD "${RUN_CMD}"
}

suppressMsgForCronJob

printAndLogTxt "Starting $HW_SCAN_NAME script ($DISCONNECTED_OS $DISCONNECTED_VERSION)"

checkCITExecutableExists "wscanhw"

isValidLocale $1 || switchLocale

# read and set setup_config.ini parameters
setupConfigParameters
prepareDirs
checkAndRotateLog

if [ "$OS_NAME" = "$OS_NAME_LINUX" -a "$VIRTUALIZATION_HOST_SCAN_ENABLED" = "true" ]; then
	printAndLogTxt "Starting virtualization host scan."
	
	/bin/bash "${FULL_TOOL_PATH}"/bin/run_vtech_scan.sh "$VTECH_WORK_DIR" "${FULL_TOOL_PATH}/config" "$VTECH_OUTPUT_DIR" "$COLLECT_HOST_HOSTNAME" "$LOGS_DIR"
	RC=$?
	if [ $RC -ne 0 ]; then 
		printAndLogTxt "Running virtualization host scan failed with return code $RC. More details can be found in run_vtech_scan.log file." 
	else
		if [ -f "$VTECH_WORK_DIR/vmman_scan_current.xml" ];then
			printAndLogTxt "Virtualization host scan finished successfully."			
			rm -f "$VTECH_WORK_DIR/vmman_scan_current.xml"
		else
			printAndLogTxt "Some unexpected problems occurred running virtualization host scan. More details can be found in run_vtech_scan.log file." 
		fi	
	fi	
fi

# ************************************************************ REGULAR CAPACITY SCAN BELOW ***************************************************************************
printAndLogTxt "Starting regular capacity scan."

ARCHIVE_DIR="${WORK_DIR}/archive"
if [ ! -d ${ARCHIVE_DIR} ]; then
	RUN_CMD="mkdir -p ${WORK_DIR}/archive"; runLogCMD "${RUN_CMD}"
fi

UNIQUE_SCANS_DIR="${WORK_DIR}/hw_scans_unique"
if [ ! -d ${UNIQUE_SCANS_DIR} ]; then
	RUN_CMD="mkdir -p ${WORK_DIR}/hw_scans_unique"; runLogCMD "${RUN_CMD}"
fi

TIME_LONG=`date -u +%Y%m%d%H%M%S`

if [ "$OS_NAME" = "$OS_NAME_LINUX" -o "$OS_NAME" = "$OS_NAME_AIX" ]; then
	TIMESTAMP=`date +%s`
else
	# on older Unix systems "date +%s" command is not supported (e.g. HPUX older than 11.31 (e.g. on 11.23) or on Solaris older than 11 (e.g. Solaris 10))
	SEC_2016_01_01="1451606400"
	AVG_SEC_YEAR="31557600"
	SEC_DAY="86400"
	SEC_HOUR="3600"
	SEC_MIN="60"
	DATE_DAYS=`date -u +%j`
	DATE_YEAR=`date -u +%Y`
	DATE_HOUR=`date -u +%H`
	DATE_MIN=`date -u +%M`
	DATE_SEC=`date -u +%S`
	TIMESTAMP=`expr ${SEC_2016_01_01} + \( ${DATE_YEAR} - 2016 \) \* ${AVG_SEC_YEAR} + \( ${DATE_DAYS} - 1 \) \* ${SEC_DAY} + ${DATE_HOUR} \* ${SEC_HOUR} + ${DATE_MIN} \* ${SEC_MIN} + ${DATE_SEC}`
fi

HW_SCAN_FILENAME="tlm_hw_${TIME_LONG}_${TIMESTAMP}.xml"
HW_SCAN_FILENAME_FULL="${ARCHIVE_DIR}/${HW_SCAN_FILENAME}"
HW_SCAN_FILENAME_FULL_TMP="${ARCHIVE_DIR}/${HW_SCAN_FILENAME}_tmp"
HW_SCAN_FILENAME_FULL_TMP_PCG="${ARCHIVE_DIR}/${HW_SCAN_FILENAME}_tmp_pcg"

runScan $HW_SCAN_TYPE "$HW_SCAN_NAME" "$STAT_HW_SCAN_LAST_PREFIX" "$CIT_HOME/bin/wscanhw -nolock -s -c \"${FULL_TOOL_PATH}/config/tlm_hw_config.xml\" -o \"${HW_SCAN_FILENAME_FULL}\""
EC=$?

if [ $EC -eq 0 ]; then

	getIdsAndTimestamp
	setupTemplates
	refreshComputerYml
	removeIpAddressAndEmptyLines

	if [ "$PUBLIC_CLOUD_TYPE" != "" ]; then
		RUN_CMD="cat \"$HW_SCAN_FILENAME_FULL\" | $GREP_CMD '<PublicCloudGuest version=\"1\">' | wc -l"; runLogCMD "${RUN_CMD}"

		# if PublicCloudGuest section does not already exist in the scan output, add it
		if [ "$CMD_OUTPUT" -eq 0 ]; then
			printAndLogTxt "Marking computer as running on public cloud: $PUBLIC_CLOUD_TYPE"
			RUN_CMD="echo \"\" > \"$HW_SCAN_FILENAME_FULL_TMP_PCG\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="echo \"        <PublicCloudGuest version=\\\"1\\\">\" >> \"$HW_SCAN_FILENAME_FULL_TMP_PCG\""; runLogCMD "${RUN_CMD}"
			if [ "$PUBLIC_CLOUD_TYPE" = "$CPT_GOOGLE_CLOUD" ]; then
				# only for google cloud the visible name "Google Compute Engine" should be changed to "Google Compute Engine Public Cloud" in HW scan to match properly (processor, PVU and computer type as a public cloud)
				RUN_CMD="echo \"                <CloudName>${PUBLIC_CLOUD_TYPE} Public Cloud</CloudName>\" >> \"$HW_SCAN_FILENAME_FULL_TMP_PCG\""; runLogCMD "${RUN_CMD}"
			else
				RUN_CMD="echo \"                <CloudName>${PUBLIC_CLOUD_TYPE}</CloudName>\" >> \"$HW_SCAN_FILENAME_FULL_TMP_PCG\""; runLogCMD "${RUN_CMD}"
			fi
			RUN_CMD="echo \"        </PublicCloudGuest>\" >> \"$HW_SCAN_FILENAME_FULL_TMP_PCG\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="sed \"/<\/Lpar>/ r $HW_SCAN_FILENAME_FULL_TMP_PCG\" \"$HW_SCAN_FILENAME_FULL\" > \"$HW_SCAN_FILENAME_FULL_TMP\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="mv -f \"$HW_SCAN_FILENAME_FULL_TMP\" \"$HW_SCAN_FILENAME_FULL\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="rm -f \"$HW_SCAN_FILENAME_FULL_TMP_PCG\""; runLogCMD "${RUN_CMD}"
		fi
		
		# Assuming ComponentID is the very first section in the HW scan output (config scan decides about that), so looking for the first occurrence of empty SerialNumber
		# if empty SerialNumber is found, a random UUID will be generated, saved to uuid.dat and used to fill the empty field each time
		serialLineFirstOccurrence="<SerialNumber>.*<\/SerialNumber>"
		serialLineEmptyToFind="<SerialNumber>[ \t]*<\/SerialNumber>"
		
		# finds the first occurrence of <SerialNumber> and checks if this first occurrence is empty
		RUN_CMD="sed -n \"/$serialLineFirstOccurrence/{p;q;}\" \"$HW_SCAN_FILENAME_FULL\" | sed -e \"s/$serialLineEmptyToFind//\" | sed -e \"s/[ \t]*//\""; runLogCMD "${RUN_CMD}"
		if [ -z "$CMD_OUTPUT" ]; then
			generatedUUIDFileName="$FULL_TOOL_PATH/config/uuid.dat"
			if [ -f "$generatedUUIDFileName" ]; then
				RUN_CMD="cat \"$generatedUUIDFileName\""; runLogCMD "${RUN_CMD}"
				newSerial=$CMD_OUTPUT
			else
				RUN_CMD="generateUUID"; runLogCMD "${RUN_CMD}"
				newSerial=$CMD_OUTPUT
				RUN_CMD="echo $newSerial > \"$generatedUUIDFileName\""; runLogCMD "${RUN_CMD}"
			fi
			serialLineNew="<SerialNumber>$newSerial<\/SerialNumber>"
			
			# created sed script to replace the first occurrence of the SerialNumber
			RUN_CMD="echo \"1{x;s/^/first/;x;}\" > \"${WORK_DIR}/sed_script_serial.tmp\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="echo \"1,/$serialLineEmptyToFind/{x;/first/s///;x;s/$serialLineEmptyToFind/$serialLineNew/;}\"  >> \"${WORK_DIR}/sed_script_serial.tmp\""; runLogCMD "${RUN_CMD}"
			
			RUN_CMD="sed -f \"${WORK_DIR}/sed_script_serial.tmp\" \"$HW_SCAN_FILENAME_FULL\" > \"$HW_SCAN_FILENAME_FULL_TMP\""; runLogCMD "${RUN_CMD}"
			
			RUN_CMD="mv -f \"$HW_SCAN_FILENAME_FULL_TMP\" \"$HW_SCAN_FILENAME_FULL\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="rm -f \"${WORK_DIR}/sed_script_serial.tmp\""; runLogCMD "${RUN_CMD}"
		fi
	fi

	# getTSUTC is called in runScan, the same time is taken and saved to STAT_HW_SCAN_CHANGED_TIME stat
	if [ ! -f "${WORK_DIR}/tlm_hw_last.xml" ]; then
		RUN_CMD="cp \"${HW_SCAN_FILENAME_FULL}\" \"${WORK_DIR}/tlm_hw_last.xml\""; runLogCMD "${RUN_CMD}"
		RUN_CMD="echo '${HW_SCAN_FILENAME}' > \"${WORK_DIR}/tlm_hw_last.filename\""; runLogCMD "${RUN_CMD}"
		RUN_CMD="cp \"${HW_SCAN_FILENAME_FULL}\" \"${UNIQUE_SCANS_DIR}/${HW_SCAN_FILENAME}\""; runLogCMD "${RUN_CMD}"
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_HW_SCAN_CHANGED_TIME}" $TSUTC
	else
		RUN_CMD="diff \"${WORK_DIR}/tlm_hw_last.xml\" \"${HW_SCAN_FILENAME_FULL}\" | wc -l"; runLogCMD "${RUN_CMD}"
		if [ "$CMD_OUTPUT" -ne 0 ]; then
			printAndLogTxt "$HW_SCAN_NAME output changed - updating..."
			updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_HW_SCAN_CHANGED_TIME}" $TSUTC
			RUN_CMD="cp \"${HW_SCAN_FILENAME_FULL}\" \"${UNIQUE_SCANS_DIR}/${HW_SCAN_FILENAME}\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="cp -f \"${HW_SCAN_FILENAME_FULL}\" \"${WORK_DIR}/tlm_hw_last.xml\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="echo '${HW_SCAN_FILENAME}' > \"${WORK_DIR}/tlm_hw_last.filename\""; runLogCMD "${RUN_CMD}"
		else
			printAndLogTxt "$HW_SCAN_NAME output identical to the previous one - update not required"
		fi
	fi
	
	updateValueInYml "${WORK_DIR}/scanner_status.yml" hw_scan_for_upload "true"
fi

printAndLogTxt "$HW_SCAN_NAME script finished"
