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

checkComputerYmlExists
checkCITExecutableExists "wscanhw"
checkCITExecutableExists "wscanfs"

setupConfigParameters
logConfigParameters
updateParametersInConfigFiles
checkPackageUpload

# run hardware scan if not in setup mode
if [ ! -n "${SETUP_MODE}" ];
then
	printAndLogTxt "Running $HW_SCAN_NAME..."
	. "$HW_SCAN_FULLPATH"	
fi

removeScanSchedule "$HW_SCAN_NAME" "$HW_SCAN_CRON_LINK_PATH"
removeScanSchedule "$SW_SCAN_NAME" "$SW_SCAN_CRON_LINK_PATH"
removeScanSchedule "$PACK_RESULTS_NAME" "$PACK_RESULTS_CRON_LINK_PATH"
removeScanSchedule "$PACK_AND_UPLOAD_RESULTS_NAME" "$PACK_AND_UPLOAD_RESULTS_CRON_LINK_PATH"
removeScanSchedule "$SW_SCAN_AND_UPLOAD_RESULTS_NAME" "$SW_SCAN_AND_UPLOAD_CRON_LINK_PATH"

scheduleScans
logScanSchedule

printAndLogTxt "Disconnected Scanner was successfully configured"
