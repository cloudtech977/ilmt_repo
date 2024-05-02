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
FULL_TOOL_PATH=`pwd`
cd "${CURR_DIR}"

. "${FULL_TOOL_PATH}"/bin/tools.sh
setupConfigParameters

printAndLogTxt "Starting uninstall script"

if [ ! -d "$CIT_HOME" ]; then
	CIT_HOME=""
fi
if [ "$CIT_HOME" != "" ]; then 
	printAndLogTxt "Removing CIT installation detected in $CIT_HOME..."
	RUN_CMD="rm -rf $CIT_HOME"; runLogCMD "${RUN_CMD}"
	printAndLogTxt "Successfully removed $CIT_HOME"
else
	printAndLogTxt "No CIT installation was found. Skipping"
fi

if $HW_SCAN_SCHEDULE_ENABLED; then 
	removeScanSchedule "$HW_SCAN_NAME" "$HW_SCAN_CRON_LINK_PATH"
fi
if $SW_SCAN_SCHEDULE_ENABLED; then 
	removeScanSchedule "$SW_SCAN_NAME" "$SW_SCAN_CRON_LINK_PATH"
	removeScanSchedule "$SW_SCAN_AND_UPLOAD_RESULTS_NAME" "$SW_SCAN_AND_UPLOAD_CRON_LINK_PATH"
fi
if $DAILY_PACK_RESULTS_CREATION_ENABLED; then 
	removeScanSchedule "$PACK_RESULTS_NAME" "$PACK_RESULTS_CRON_LINK_PATH"
	removeScanSchedule "$PACK_AND_UPLOAD_RESULTS_NAME" "$PACK_AND_UPLOAD_RESULTS_CRON_LINK_PATH"
fi

deleteCronLinks

printAndLogTxt "Directories removal started..."
removeDirs
if [ "$EC" -eq 0 ]; then
	printTxt "Directories removed successfully"
else
	printTxt "WARNING: Directories removing failure"
fi

printTxt "Uninstallation finished"
