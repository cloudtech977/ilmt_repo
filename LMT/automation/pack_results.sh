#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2020. All Rights Reserved.
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

createOutputPackage() 
{
	printAndLogTxt "Preparing the output package with scan results..."

	getValueFromYml "${WORK_DIR}/scanner_status.yml" sw_scan_for_upload
	SW_SCAN_DONE=$YML_VAL

	getValueFromYml "${WORK_DIR}/scanner_status.yml" hw_scan_for_upload
	HW_SCAN_DONE=$YML_VAL
	
	HWLASTFILE=`cat ${WORK_DIR}/tlm_hw_last.filename`
	
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		VMMAN_SCAN_DONE=false
		if $VMM_TOOL_INSTALLED; then
			if [ `ls "${VMM_TOOL_PATH}/upload" | grep "vmman_scan_.*xml" | wc -l` -gt 0 ]; then
				VMMAN_SCAN_DONE=true
			fi
		fi
		VTECH_SCAN_DONE=false
		if [ "$VIRTUALIZATION_HOST_SCAN_ENABLED" = "true" ]; then
			if [ `ls "${VTECH_OUTPUT_DIR}" | grep "vmman_scan_.*xml" | wc -l` -gt 0 ]; then
				VTECH_SCAN_DONE=true
			fi
		fi
	fi

	ENDPOINT_ID=`cat ${WORK_DIR}/computer.yml | grep endpointID | awk -F\  {'print $2'}`
	TIME_SHORT=`date -u +%Y%m%d%H%M`
	RUN_CMD="tar cf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR computer.yml"; runLogCMD "${RUN_CMD}"

	if [ -f "${FULL_TOOL_PATH}/config/computer_properties.yml" ]; then
		RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C ${FULL_TOOL_PATH}/config computer_properties.yml"; runLogCMD "${RUN_CMD}"
	fi    

	if [ "${HW_SCAN_DONE}" = "true" -o "${SW_SCAN_DONE}" = "true" ]; then
		TAR_MODE="cf"
		for NAME in "${WORK_DIR}/hw_scans_unique"/*.xml; do	
			xmlFileName=`basename ${NAME}`	
			SGN_FILE_NAME=${xmlFileName}.sgn
			if [ -f "$WORK_DIR/archive/${SGN_FILE_NAME}" ]; then
				RUN_CMD="tar $TAR_MODE \"$WORK_DIR/signatures.tar\" -C \"$WORK_DIR/archive\" ${SGN_FILE_NAME}"; runLogCMD "${RUN_CMD}"
				TAR_MODE="uf"
			fi
		done			
		RUN_CMD="tar cf $WORK_DIR/capacity.tar -C $WORK_DIR/hw_scans_unique ."; runLogCMD "${RUN_CMD}"
		if [ -f "${WORK_DIR}/tlmsubcapacity.cfg" ]; then
			RUN_CMD="tar uf $WORK_DIR/capacity.tar -C $WORK_DIR tlmsubcapacity.cfg"; runLogCMD "${RUN_CMD}"
		fi
		if [ -f "${WORK_DIR}/dsd_enabled" ]; then
			RUN_CMD="tar uf \"$WORK_DIR/capacity.tar\" -C \"$WORK_DIR\" dsd_enabled"; runLogCMD "${RUN_CMD}"
		fi
		RUN_CMD="rm -rf $WORK_DIR/capacity.tar.gz"; runLogCMD "${RUN_CMD}"
		RUN_CMD="gzip $WORK_DIR/capacity.tar"; runLogCMD "${RUN_CMD}"

		RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR capacity.tar.gz"; runLogCMD "${RUN_CMD}"

		if [ "$ISOTAG_SCAN_ENABLED" = "true" -o "$DOCKER_SCAN_ENABLED" = "true" ]; then
		
			getValueFromYml "${WORK_DIR}/scanner_status.yml" "${STAT_ISOTAG_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}"
			SCAN_STATUS=$YML_VAL
		
			# redirecting "unary operator expected" error to null if scan statuses not yet initialized (empty) after fresh installation
			if [ $SCAN_STATUS -eq 0 2>/dev/null ]; then
				if [ -f "${ISOTAG_DIR}/list.txt" ]; then
					RUN_CMD="tar cf $WORK_DIR/isotag_scan.tar -C $ISOTAG_DIR list.txt"; runLogCMD "${RUN_CMD}"
					RUN_CMD="rm $ISOTAG_DIR/list.txt"; runLogCMD "${RUN_CMD}"

					find "$ISOTAG_DIR" -type f | while read file; do
						filevar=`basename $file`
						RUN_CMD="tar uf $WORK_DIR/isotag_scan.tar -C $ISOTAG_DIR $filevar"; runCMDOnly "${RUN_CMD}"  
					done

					RUN_CMD="rm -rf $WORK_DIR/isotag_scan.tar.gz"; runLogCMD "${RUN_CMD}"
					RUN_CMD="gzip $WORK_DIR/isotag_scan.tar"; runLogCMD "${RUN_CMD}"
				fi
				
				ISOTAG_SCAN_PKG="isotag_scan.tar.gz"
				ISOTAG_SCAN_XML="isotag_scan.xml"
				ISOTAG_SCAN_SIG="${ISOTAG_SCAN_XML}.sgn"

				if [ -f "${WORK_DIR}/${ISOTAG_SCAN_SIG}" ]; then
					RUN_CMD="tar $TAR_MODE $WORK_DIR/signatures.tar -C $WORK_DIR  ${ISOTAG_SCAN_SIG}"; runLogCMD "${RUN_CMD}"
					TAR_MODE="uf"
				fi

				if [ -f "${WORK_DIR}/${ISOTAG_SCAN_PKG}" ]; then 
					RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR ${ISOTAG_SCAN_PKG}"; runLogCMD "${RUN_CMD}"
				fi
			fi
		fi

		if $CATALOG_SCAN_ENABLED; then
		
			getValueFromYml "${WORK_DIR}/scanner_status.yml" "${STAT_CATALOG_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}"
			SCAN_STATUS=$YML_VAL
		
			if [ $SCAN_STATUS -eq 0 2>/dev/null ]; then
				CATALOG_SCAN_XML="catalog_scan.xml"
				CATALOG_SCAN_SIG="${CATALOG_SCAN_XML}.sgn"

				if [ -f "${WORK_DIR}/${CATALOG_SCAN_SIG}" ]; then
					RUN_CMD="tar $TAR_MODE $WORK_DIR/signatures.tar -C $WORK_DIR ${CATALOG_SCAN_SIG}"; runLogCMD "${RUN_CMD}"
					TAR_MODE="uf"
				fi
				
				if [ -f "${WORK_DIR}/${CATALOG_SCAN_XML}" ]; then 
					RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR ${CATALOG_SCAN_XML}"; runLogCMD "${RUN_CMD}"
				fi				
			fi
		fi

		if $PACKAGE_SCAN_ENABLED; then
		
			getValueFromYml "${WORK_DIR}/scanner_status.yml" "${STAT_PACKAGE_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}"
			SCAN_STATUS=$YML_VAL
		
			if [ $SCAN_STATUS -eq 0 2>/dev/null ]; then
				PACKAGE_SCAN_XML="package_scan.xml"
				PACKAGE_SCAN_SIG="${PACKAGE_SCAN_XML}.sgn"

				if [ -f "${WORK_DIR}/${PACKAGE_SCAN_SIG}" ]; then
					RUN_CMD="tar $TAR_MODE $WORK_DIR/signatures.tar -C $WORK_DIR ${PACKAGE_SCAN_SIG}"; runLogCMD "${RUN_CMD}"
					TAR_MODE="uf"
				fi
				
				if [ -f "${WORK_DIR}/${PACKAGE_SCAN_XML}" ]; then 
					RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR ${PACKAGE_SCAN_XML}"; runLogCMD "${RUN_CMD}"
				fi				
			fi
		fi
		
		if $SLMTAG_SCAN_ENABLED; then
		
			getValueFromYml "${WORK_DIR}/scanner_status.yml" "${STAT_SLMTAG_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}"
			SCAN_STATUS=$YML_VAL
		
			if [ $SCAN_STATUS -eq 0 2>/dev/null ]; then
				if [ -f "${SLMTAG_DIR}/list.txt" ]; then
					RUN_CMD="tar cf $WORK_DIR/slmtag_scan.tar -C $SLMTAG_DIR list.txt"; runLogCMD "${RUN_CMD}"
					RUN_CMD="rm $SLMTAG_DIR/list.txt"; runLogCMD "${RUN_CMD}"

					find "$SLMTAG_DIR" -type f | while read file; do
						filevar=`basename $file`
						RUN_CMD="tar uf $WORK_DIR/slmtag_scan.tar -C $SLMTAG_DIR $filevar"; runCMDOnly "${RUN_CMD}"  
					done

					RUN_CMD="rm -rf $WORK_DIR/slmtag_scan.tar.gz"; runLogCMD "${RUN_CMD}"
					RUN_CMD="gzip $WORK_DIR/slmtag_scan.tar"; runLogCMD "${RUN_CMD}"
				fi
				
				SLMTAG_SCAN_PKG="slmtag_scan.tar.gz"
				SLMTAG_SCAN_XML="slmtag_scan.xml"
				SLMTAG_SCAN_SIG="${SLMTAG_SCAN_XML}.sgn"

				if [ -f "${WORK_DIR}/${SLMTAG_SCAN_SIG}" ]; then
					RUN_CMD="tar $TAR_MODE $WORK_DIR/signatures.tar -C $WORK_DIR  ${SLMTAG_SCAN_SIG}"; runLogCMD "${RUN_CMD}"
					TAR_MODE="uf"	
				fi

				if [ -f "${WORK_DIR}/${SLMTAG_SCAN_PKG}" ]; then 
					RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR ${SLMTAG_SCAN_PKG}"; runLogCMD "${RUN_CMD}"
				fi
				
				if [ -f "$MARKER_FILE_COMPARE" ]; then 
					RUN_CMD="mv -f $MARKER_FILE_COMPARE $MARKER_FILE"; runLogCMD "${RUN_CMD}"
				fi
			fi
		fi

		if [ -f "${WORK_DIR}/signatures.tar" ]; then
			RUN_CMD="rm -rf $WORK_DIR/signatures.tar.gz"; runLogCMD "${RUN_CMD}"
			RUN_CMD="gzip $WORK_DIR/signatures.tar"; runLogCMD "${RUN_CMD}"
			RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR signatures.tar.gz"; runLogCMD "${RUN_CMD}"
		fi
	else
		RUN_CMD="cp \"$WORK_DIR/tlm_hw_last.xml\" \"$WORK_DIR/hw_scans_unique/${HWLASTFILE}\""; runLogCMD "${RUN_CMD}"
		RUN_CMD="tar cf $WORK_DIR/capacity.tar -C $WORK_DIR/hw_scans_unique $HWLASTFILE"; runLogCMD "${RUN_CMD}"
		if [ -f "${WORK_DIR}/tlmsubcapacity.cfg" ]; then
			RUN_CMD="tar uf $WORK_DIR/capacity.tar -C $WORK_DIR tlmsubcapacity.cfg"; runLogCMD "${RUN_CMD}"
		fi
		if [ -f "${WORK_DIR}/dsd_enabled" ]; then
			RUN_CMD="tar uf \"$WORK_DIR/capacity.tar\" -C \"$WORK_DIR\" dsd_enabled"; runLogCMD "${RUN_CMD}"
		fi
		RUN_CMD="rm -rf $WORK_DIR/capacity.tar.gz"; runLogCMD "${RUN_CMD}"
		RUN_CMD="gzip $WORK_DIR/capacity.tar"; runLogCMD "${RUN_CMD}"
		RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR capacity.tar.gz"; runLogCMD "${RUN_CMD}"	
	fi
	
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		if $VMMAN_SCAN_DONE; then
			getValueFromYml "${WORK_DIR}/scanner_status.yml" vmman_package_num
			VMM_TOOL_PACKAGE_NUM=$YML_VAL
			RUN_CMD="rm -f ${VMM_TOOL_SCAN_DIR}/${VMM_TOOL_PACKAGE_NUM}_vmman.tar.gz"; runLogCMD "${RUN_CMD}"

			# tar doesn't work with wildcards and -C option so we must use find to get the list of files and pass that to tar
			# -printf "%f " in the find command is used to output only the file name without the path to the file
			if $VTECH_SCAN_DONE; then
				RUN_CMD="mv '${VTECH_OUTPUT_DIR}/'vmman_scan_*.xml '${VMM_TOOL_PATH}/upload'"; runLogCMD "${RUN_CMD}"
			fi
			RUN_CMD="ls '${VMM_TOOL_PATH}/upload' | grep \"vmman_scan_.*xml\" | xargs tar cf $VMM_TOOL_SCAN_DIR/${VMM_TOOL_PACKAGE_NUM}_vmman.tar -C '${VMM_TOOL_PATH}/upload'"; runLogCMD "${RUN_CMD}"
			RUN_CMD="rm -rf $VMM_TOOL_SCAN_DIR/${VMM_TOOL_PACKAGE_NUM}_vmman.tar.gz"; runLogCMD "${RUN_CMD}" 
			RUN_CMD="gzip $VMM_TOOL_SCAN_DIR/${VMM_TOOL_PACKAGE_NUM}_vmman.tar"; runLogCMD "${RUN_CMD}"
			RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C ${VMM_TOOL_SCAN_DIR} ${VMM_TOOL_PACKAGE_NUM}_vmman.tar.gz"; runLogCMD "${RUN_CMD}" 

			#increment vmman_package_num in scanner_status (modulo 10 operation)
			VMM_TOOL_PACKAGE_NUM_TMP=`expr $VMM_TOOL_PACKAGE_NUM + 1`
			VMM_TOOL_PACKAGE_NUM=`expr $VMM_TOOL_PACKAGE_NUM_TMP % 10`
			updateValueInYml "${WORK_DIR}/scanner_status.yml" vmman_package_num $VMM_TOOL_PACKAGE_NUM
		else
			if $VTECH_SCAN_DONE; then
				getValueFromYml "${WORK_DIR}/scanner_status.yml" vmman_package_num
				VMM_TOOL_PACKAGE_NUM=$YML_VAL
				RUN_CMD="rm -f ${VMM_TOOL_SCAN_DIR}/${VMM_TOOL_PACKAGE_NUM}_vmman.tar.gz"; runLogCMD "${RUN_CMD}"
	
				# tar doesn't work with wildcards and -C option so we must use find to get the list of files and pass that to tar
				# -printf "%f " in the find command is used to output only the file name without the path to the file
				RUN_CMD="ls '${VTECH_OUTPUT_DIR}' | grep \"vmman_scan_.*xml\" | xargs tar cf $VMM_TOOL_SCAN_DIR/${VMM_TOOL_PACKAGE_NUM}_vmman.tar -C '${VTECH_OUTPUT_DIR}'"; runLogCMD "${RUN_CMD}"
				RUN_CMD="rm -rf $VMM_TOOL_SCAN_DIR/${VMM_TOOL_PACKAGE_NUM}_vmman.tar.gz"; runLogCMD "${RUN_CMD}" 
				RUN_CMD="gzip $VMM_TOOL_SCAN_DIR/${VMM_TOOL_PACKAGE_NUM}_vmman.tar"; runLogCMD "${RUN_CMD}"
				RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C ${VMM_TOOL_SCAN_DIR} ${VMM_TOOL_PACKAGE_NUM}_vmman.tar.gz"; runLogCMD "${RUN_CMD}" 
	
				#increment vmman_package_num in scanner_status (modulo 10 operation)
				VMM_TOOL_PACKAGE_NUM_TMP=`expr $VMM_TOOL_PACKAGE_NUM + 1`
				VMM_TOOL_PACKAGE_NUM=`expr $VMM_TOOL_PACKAGE_NUM_TMP % 10`
				updateValueInYml "${WORK_DIR}/scanner_status.yml" vmman_package_num $VMM_TOOL_PACKAGE_NUM
			fi
		fi
			
	fi
	
	#updateOperationStats will update scanner_status.yml, so it must be packed as the last file
	updateOperationStats $EC "$PACK_RESULTS_NAME" "$STAT_PACK_RESULTS_LAST_PREFIX" "Scan results package creation failed - return code $EC"
	
	RUN_CMD="tar uf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar -C $WORK_DIR scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="rm -rf $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar.gz"; runLogCMD "${RUN_CMD}"
	RUN_CMD="gzip $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar"; runLogCMD "${RUN_CMD}"
	RUN_CMD="mv $WORK_DIR/${TIME_SHORT}-${ENDPOINT_ID}.tar.gz $PACKAGE_OUTPUT_DIR"; runLogCMD "${RUN_CMD}"
	
	#in case of an error in this phase update the stats one more time (it will also reprint PACK_RESULTS_NAME operation status)
	[ $EC -ne 0 ] && updateOperationStats $EC "$PACK_RESULTS_NAME" "$STAT_PACK_RESULTS_LAST_PREFIX" "Scan results package last step failed - return code $EC"
}

cleanOutputDirs()
{
	printAndLogTxt "Cleaning up the output directories..."
	if [ "${ISOTAG_DIR}" != "" ]; then
		RUN_CMD="rm -f $ISOTAG_DIR/*"; runLogCMD "${RUN_CMD}"
	fi
	
	if [ "${SLMTAG_DIR}" != "" ]; then
		RUN_CMD="rm -f $SLMTAG_DIR/*"; runLogCMD "${RUN_CMD}"
	fi

	if [ "${WORK_DIR}" != "" ]; then 
		RUN_CMD="rm -f $WORK_DIR/*.tar.gz"; runLogCMD "${RUN_CMD}"
		RUN_CMD="rm -f $WORK_DIR/package_scan*"; runLogCMD "${RUN_CMD}"
		RUN_CMD="rm -f $WORK_DIR/catalog_scan*"; runLogCMD "${RUN_CMD}"
		RUN_CMD="rm -f $WORK_DIR/archive/tlm*"; runLogCMD "${RUN_CMD}"
		RUN_CMD="rm -f $WORK_DIR/hw_scans_unique/tlm*"; runLogCMD "${RUN_CMD}"

		updateValueInYml "${WORK_DIR}/scanner_status.yml" sw_scan_for_upload "false"
		updateValueInYml "${WORK_DIR}/scanner_status.yml" hw_scan_for_upload "false"

		if [ -f "$WORK_DIR/tlm_hw_last.filename" -a -f "$WORK_DIR/tlm_hw_last.xml" ]; then
			LAST_HW_SCAN_NAME=`cat "$WORK_DIR/tlm_hw_last.filename"`
			RUN_CMD="cp \"$WORK_DIR/tlm_hw_last.xml\" \"$WORK_DIR/hw_scans_unique/${LAST_HW_SCAN_NAME}\""; runLogCMD "${RUN_CMD}"
		else
			RUN_CMD="rm -f \"$WORK_DIR/tlm_hw_last.xml\""; runLogCMD "${RUN_CMD}"
		fi
	fi

	if [ "${TEMP_DIR}" != "" ]; then 
		RUN_CMD="rm -rf $TEMP_DIR"; runLogCMD "${RUN_CMD}"
	fi

	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		if $VMMAN_SCAN_DONE; then
			printAndLogTxt "Remove VM Manager Tool scans."
			cd "${VMM_TOOL_PATH}/upload"
			RUN_CMD="rm -rf vmman_scan_*.xml"; runLogCMD "${RUN_CMD}"
			cd "${CURR_DIR}"
		fi
		if $VTECH_SCAN_DONE; then
			printAndLogTxt "Remove Virtualization Host scans."
			cd "${VTECH_OUTPUT_DIR}"
			RUN_CMD="rm -rf vmman_scan_*.xml"; runLogCMD "${RUN_CMD}"
			cd "${CURR_DIR}"
		fi		
	fi
}

removeOldScans(){
	if [ $NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP -gt 0 ]; then
		RUN_CMD="ls -td $PACKAGE_OUTPUT_DIR/*.tar.gz 2>/dev/null | sed -e '1,${NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP}d' | wc -l"; runLogCMD "${RUN_CMD}"
		if [ "$CMD_OUTPUT" -gt 0 ]; then 
			RUN_CMD="ls -td $PACKAGE_OUTPUT_DIR/*.tar.gz | sed -e '1,${NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP}d' | xargs rm"; runLogCMD "${RUN_CMD}"
		fi	
	fi
}

printAndLogTxt "Starting $PACK_RESULTS_NAME script ($DISCONNECTED_OS $DISCONNECTED_VERSION)"

checkComputerYmlExists

setupConfigParameters
prepareDirs
detectVMMTool

. "${FULL_TOOL_PATH}"/bin/del_expired_hw_scans.sh

createOutputPackage
cleanOutputDirs
removeOldScans

printAndLogTxt "Package ${TIME_SHORT}-${ENDPOINT_ID}.tar.gz created in the output directory - upload it to ILMT"
