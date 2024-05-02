#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2017. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##################################################################################

# Definition of common global settings

# OS name from uname command (available values: AIX, Linux, SunOS)
OS_NAME=`uname -s`
OS_NAME_AIX="AIX"
OS_NAME_LINUX="Linux"
OS_NAME_SOLARIS="SunOS"

# OS name for which a given disconnected scanner package is targeted (available values: aix, linux, solaris)
DISCONNECTED_OS="linux"
DISCONNECTED_OS_AIX="aix"
DISCONNECTED_OS_LINUX="linux"
DISCONNECTED_OS_SOLARIS="solaris"

DISCONNECTED_VERSION="9.2.30.0"
DISCONNECTED_ISOTAG_NAME="ibm.com_IBM_License_Metric_Tool-9.2.30.0.swidtag"
CIT_CATALOG_PATH=$FULL_TOOL_PATH/config/CIT_catalog_LINUX.xml
# the value used if the catalog scan is not enabled and CIT catalog is not provided
CATALOG_VER="1313082.0"


# setup environment
unalias -a

CIT_HOME="$FULL_TOOL_PATH/cit"
LD_LIBRARY_PATH=$CIT_HOME/bin;   export LD_LIBRARY_PATH
DYLD_LIBRARY_PATH=$CIT_HOME/bin; export DYLD_LIBRARY_PATH
SHLIB_PATH=$CIT_HOME/bin;        export SHLIB_PATH
LIBPATH=$CIT_HOME/bin;           export LIBPATH

DSCANNER_CONFIG=${FULL_TOOL_PATH}/config/setup_config.ini

# All error codes of disconnected scanner scripts (negative)
# Note: CIT scanner return codes are from 0 to 125 (positive), return codes higher than 128 means a process was ended by a signal
# (to find out the signal number use the following calculation: return code - 128 = operating system signal)
DS_RC_OK=0

# Docker scan script errors
DS_RC_DOCKER_DIR_NOT_FOUND=-1
DS_RC_DOCKER_CMD_MISSING=-2
DS_RC_DOCKER_CMD_INFO_FAILED=-3

# ISO tag scan script errors
DS_RC_ISOTAG_COPYING_FAILED=-10

DS_RC_SLMTAG_COPYING_FAILED=-11

# Scan results packaging script errors
DS_RC_PACKAGE_CREATION_FAILED=-20

# CIT installation errors
DS_RC_INST_UNSUPPORTED_OS=-30
DS_RC_INST_UNSUPPORTED_ARCH=-31
DS_RC_INST_CITBUNDLE_NOT_FOUND=-32
DS_RC_INST_CITBUNDLE_CANNOT_UPACK=-33
DS_RC_INST_WCITINST_CANNOT_RUN=-34
DS_RC_INST_CIT_SPB_CANNOT_FIND=-35
DS_RC_INST_CIT_HOME_NOT_SET=-36
DS_RC_INST_CIT_INSTALLATION_FAILED=-37


# Variables for scan statistics
STAT_SW_SCAN_LAST_ALL_NAMES=""
# for SW_SCAN_NAME="Software Scan"
STAT_SW_SCAN_LAST_PREFIX="last_sw_scan"
STAT_SW_SCAN_LAST_ALL_NAMES="${STAT_SW_SCAN_LAST_ALL_NAMES} ${STAT_SW_SCAN_LAST_PREFIX}"
# for PACKAGE_SCAN_NAME="Package Scan"
STAT_PACKAGE_SCAN_LAST_PREFIX="last_sw_package_scan"
STAT_SW_SCAN_LAST_ALL_NAMES="${STAT_SW_SCAN_LAST_ALL_NAMES} ${STAT_PACKAGE_SCAN_LAST_PREFIX}"
# for ISOTAG_SCAN_NAME="ISO-tag Scan"
STAT_ISOTAG_SCAN_LAST_PREFIX="last_sw_iso_scan"
STAT_SW_SCAN_LAST_ALL_NAMES="${STAT_SW_SCAN_LAST_ALL_NAMES} ${STAT_ISOTAG_SCAN_LAST_PREFIX}"
# for CATALOG_SCAN_NAME="Catalog Based Scan"
STAT_CATALOG_SCAN_LAST_PREFIX="last_sw_catalog_scan"
STAT_SW_SCAN_LAST_ALL_NAMES="${STAT_SW_SCAN_LAST_ALL_NAMES} ${STAT_CATALOG_SCAN_LAST_PREFIX}"
# for DOCKER_SCAN_NAME="Docker Scan"
STAT_DOCKER_SCAN_LAST_PREFIX="last_sw_docker_scan"
STAT_SW_SCAN_LAST_ALL_NAMES="${STAT_SW_SCAN_LAST_ALL_NAMES} ${STAT_DOCKER_SCAN_LAST_PREFIX}"
# for SLMTAG_SCAN_NAME="SLM-tag Scan"
STAT_SLMTAG_SCAN_LAST_PREFIX="last_sw_slm_scan"
STAT_SW_SCAN_LAST_ALL_NAMES="${STAT_SW_SCAN_LAST_ALL_NAMES} ${STAT_SLMTAG_SCAN_LAST_PREFIX}"

STAT_LAST_STATUS_SUFFIX="_status"
STAT_LAST_TIME_SUFFIX="_time"
STAT_LAST_OK_TIME_SUFFIX="_success_time"

STAT_PACK_RESULTS_LAST_PREFIX="last_results_packaging"
PACK_RESULTS_NAME="Scan Results Packaging"

STAT_UPLOAD_RESULTS_LAST_PREFIX="last_results_upload"
UPLOAD_RESULTS_NAME="Scan Results Upload"

STAT_PACK_AND_UPLOAD_RESULTS_LAST_PREFIX="last_results_pack_and_upload"
PACK_AND_UPLOAD_RESULTS_NAME="Scan Results Pack and Upload"

STAT_SW_SCAN_AND_UPLOAD_RESULTS_LAST_PREFIX="last_results_sw_scan_and_upload"
SW_SCAN_AND_UPLOAD_RESULTS_NAME="Software Scan and Upload"

# Names' definitions for all parts of software scan (type SW)
SW_SCAN_TYPE="SW"
SW_SCAN_NAME="Software Scan"
PACKAGE_SCAN_NAME="Package Scan"
ISOTAG_SCAN_NAME="ISO-tag Scan"
CATALOG_SCAN_NAME="Catalog Based Scan"
DOCKER_SCAN_NAME="Docker Scan"
SLMTAG_SCAN_NAME="SLM Scan"


# Names' definitions for hardware scan (type HW)
HW_SCAN_TYPE="HW"
HW_SCAN_NAME="Hardware Scan"
STAT_HW_SCAN_LAST_PREFIX="last_hw_scan"
STAT_HW_SCAN_CHANGED_TIME="last_hw_scan_change_time"

SW_SCAN_FULLPATH="${FULL_TOOL_PATH}/run_sw_and_pack.sh"
SW_SCAN_CRON_LINK_PATH="${FULL_TOOL_PATH}/bin/run_sw_and_pack_CRON.sh"
SW_SCAN_AND_UPLOAD_FULLPATH="${FULL_TOOL_PATH}/automation/run_sw_and_upload.sh"
SW_SCAN_AND_UPLOAD_CRON_LINK_PATH="${FULL_TOOL_PATH}/bin/run_sw_and_upload_CRON.sh"
HW_SCAN_FULLPATH="${FULL_TOOL_PATH}/bin/run_hw.sh"
HW_SCAN_CRON_LINK_PATH="${FULL_TOOL_PATH}/bin/run_hw_CRON.sh"
PACK_RESULTS_FULL_PATH="${FULL_TOOL_PATH}/automation/pack_results.sh"
PACK_RESULTS_CRON_LINK_PATH="${FULL_TOOL_PATH}/bin/pack_results_CRON.sh"
PACK_AND_UPLOAD_RESULTS_FULL_PATH="${FULL_TOOL_PATH}/automation/pack_and_upload_results.sh"
PACK_AND_UPLOAD_RESULTS_CRON_LINK_PATH="${FULL_TOOL_PATH}/bin/pack_and_upload_results_CRON.sh"


# default docker settings:
# default docker command
DOCKER_CMD=docker
# a list of paths excluded when scanning inside of containers
DOCKER_EXCLUDED_PATHS="/LMT/CIT /overlay /overlay2 /devicemapper"
# the path for "scoped" ISO tag scan (only this 1 dir is scanned) for ISO tags discovered in docker containers
# be careful if you change any element of work/docker_scan/containers path...
DOCKER_SCAN_DIR_FOR_ISOTAG_SCAN="$FULL_TOOL_PATH/work/docker_scan/containers"

# timestamp files for slmtag scan, one is created during scan, second after packing
MARKER_FILE="${FULL_TOOL_PATH}/work/slmtagsPackTimeMarker"
MARKER_FILE_COMPARE="${FULL_TOOL_PATH}/work/slmtagsTimeMarkerCompare"

# supported public cloud providers' types
CPT_IBM_POWER="IBM Power Virtual Server"
CPT_IBM_SOFTLAYER="IBM SoftLayer"
CPT_IBM_CLOUD_LINUXONE="IBM Cloud LinuxONE VS"
CPT_MS_AZURE="Microsoft Azure"
CPT_AMAZON_EC2="Amazon EC2"
CPT_GOOGLE_CLOUD="Google Compute Engine"
CPT_ORACLE_CLOUD="Oracle Compute Instance"
CPT_ALIBABA_CLOUD="Alibaba Elastic Compute Service"
CPT_TENCENT_CLOUD="Tencent Cloud Server Instance"
CPT_NEC_CLOUD="NEC Cloud IaaS Instance"
CPT_FUJITSU_CLOUD="Fujitsu Cloud IaaS Instance"
CPT_NTT_ECL="NTT Enterprise Cloud Server"
CPT_NTT_VMWARE="NTT IaaS Powered by VMware"
CPT_KDDI_VS="KDDI Virtual Server"

LOGS_DIR="${FULL_TOOL_PATH}/logs"
if [ ! -d ${LOGS_DIR} ]; then
	mkdir -p "${FULL_TOOL_PATH}/logs"
fi
LOG_FILE=${LOGS_DIR}/log.txt

# this is to make sure that the TAB character we use is correct on all platforms
# passing '\t' to sed can be ambiguous, but tr interprets it the same way on all systems
tab_tmp="t"
TAB=`echo $tab_tmp | tr 't' '\t'`


#DEFINITION OF FUNCTIONS

getTS()
{
	TS="(`date +'%Y-%m-%d %H:%M:%S'`)"
}

getTSUTC()
{
	TSUTC="`date -u +'%Y-%m-%dT%H:%M:%SZ'`"
}

# use to print on screen and log
printAndLogTxt()
{
	getTS
	if [ "$SUPPRESS_OUTPUT" = true ]; then
		# if empty, log timestamp only
		if [ "$1" = "" ]; then
			logTxt "$TS"
		else
			logTxt "$TS $1"
		fi
	else
		# if empty, log timestamp only
		if [ "$1" = "" ]; then
			echo "$TS" | tee -a $LOG_FILE
		else
			echo "$TS $1" | tee -a $LOG_FILE
		fi
	fi
}

# use to print on screen and log and exit with a code
printAndLogTxtExit()
{
	printAndLogTxt "ERROR: $1"
	# default return code is 1 if not passed to the function
	RC=1
	[ -n "$2" ] && RC=$2
	exit $RC
}

# use to print on screen only
printTxt()
{
	getTS
	if [ "$SUPPRESS_OUTPUT" != true ]; then
		# if empty, log timestamp only
		if [ "$1" = "" ]; then
			echo "$TS"
		else
			echo "$TS $1"
		fi
	fi
}

# use to log only
logTxt()
{
	getTS
	# if empty, log timestamp only
	if [ "$1" = "" ]; then
		echo "$TS" >> $LOG_FILE
	else
		echo "$TS $1" >> $LOG_FILE
	fi
}

# use to log only without timestamp (continue logging of multiline text)
logTxtCont()
{
	echo "$1" >> $LOG_FILE
}

checkAndRotateLog()
{
	if [ -f "${LOG_FILE}" ]; then
		LOG_SIZE=`wc -c "${LOG_FILE}" | awk '{print $1}'`
	else
		LOG_SIZE="0"
	fi

	# rotate the log file if size (actual space on disk) is greater then 10 MB
	if [ "${LOG_SIZE}" -gt "10000000" ]; then
		rm -f "${LOG_FILE}.1"
		mv "${LOG_FILE}" "${LOG_FILE}.1"
	fi
}

# "internal" - do not use, instead use run*CMD* functions below
internalRunCMD()
{
	CMD_OUTPUT=`eval "$1"`
	EC=$?
	if [ $EC -ne 0 ]; then printAndLogTxt "command: $1 --- WARNING: non-zero return code: $EC"; fi
	return $EC
}

# "internal" - do not use, instead use run*CMD* functions below (no output to console)
internalRunCMDlogOnly()
{
	CMD_OUTPUT=`eval "$1"`
	EC=$?
	if [ $EC -ne 0 ]; then logTxt "command: $1 --- WARNING: non-zero return code: $EC"; fi
	return $EC
}

# Runs a command (no error redirection) and prints on screen only if non-zero return code
# use e.g. for commands run in a loop (logging everything does not make sense)
runCMDOnly()
{
	internalRunCMD "$1"
}

# Runs a command (no error redirection), logs the command line and prints on screen only if non-zero return code
# use in most of the cases
runLogCMD()
{
	logTxt "--- running command: '$1'"
	internalRunCMD "$1"
}

# Runs a command (no error redirection), logs the command line 
runLogCMDlogOnly()
{
	logTxt "--- running command: '$1'"
	internalRunCMDlogOnly "$1"
}

# The same as runLogCMD, but does error stream redirection and then writes full output of a command to log
# use when you need to log the output of the command (for information/debugging purposes)
runLogCMDWithOutput()
{
	logTxt "--- running command: '$1':"
	internalRunCMD "$1 2>&1"
	logTxtCont "$CMD_OUTPUT"
}

getHWScanData()
{
	CMD="grep \"$1\" \"$2\" | cut -f2 -d\">\" | cut -f1 -d\"<\" | head -1"
	CMD_OUTPUT=`eval $CMD`
}

getHWScanDataAllInstances()
{
	CMD="grep \"$1\" \"$2\" | cut -f2 -d\">\" | cut -f1 -d\"<\" | sed 's/^/ /g'"
	CMD_OUTPUT=`eval $CMD`
}

checkInstallDir()
{
	if [ `printf '%s' "${FULL_TOOL_PATH}" | tr -d ' \t\n'` != "${FULL_TOOL_PATH}" ]; then
		printAndLogTxtExit "The installation path \"${FULL_TOOL_PATH}\" contains white space characters. Ensure that the installation path does not contain any unsupported characters."
	fi
}

prepareDirs()
{
	cd "$FULL_TOOL_PATH"

	TAG_DIR="${FULL_TOOL_PATH}/iso-swid"
	RUN_CMD="ls -1 \"${TAG_DIR}\"/*.swidtag | grep -v \"$DISCONNECTED_ISOTAG_NAME\" | xargs -I@ rm -f \"@\""; runLogCMD "${RUN_CMD}"

	if [ ! -f "${TAG_DIR}/$DISCONNECTED_ISOTAG_NAME" ]; then
		printAndLogTxtExit "Disconnected Scanner not properly extracted: ISO Tag file ${TAG_DIR}/$DISCONNECTED_ISOTAG_NAME not found."
	fi

	if [ ! -n "$PACKAGE_OUTPUT_DIR" ]; then
		printAndLogTxtExit "PACKAGE_OUTPUT_DIR is not set - Check config/setup_config.ini!"
	fi

	if [ ! -d "${PACKAGE_OUTPUT_DIR}" ]; then
		RUN_CMD="mkdir -p $PACKAGE_OUTPUT_DIR"; runLogCMD "${RUN_CMD}"
	fi

	WORK_DIR="${FULL_TOOL_PATH}/work"
	if [ ! -d ${WORK_DIR} ]; then
		RUN_CMD="mkdir -p $WORK_DIR"; runLogCMD "${RUN_CMD}"
	fi

	TEMP_DIR="${FULL_TOOL_PATH}/tempdir"
	if [ -d ${TEMP_DIR} ]; then
		RUN_CMD="mkdir -p $TEMP_DIR"; runLogCMD "${RUN_CMD}"
	fi

	ISOTAG_DIR="${WORK_DIR}/isotag_scan"
	if [ ! -d ${ISOTAG_DIR} ]; then
		RUN_CMD="mkdir -p $ISOTAG_DIR"; runLogCMD "${RUN_CMD}"
	fi
	
	SLMTAG_DIR="${WORK_DIR}/slmtag_scan"
	if [ ! -d ${SLMTAG_DIR} ]; then
		RUN_CMD="mkdir -p $SLMTAG_DIR"; runLogCMD "${RUN_CMD}"
	fi

	LOGS_DIR="${FULL_TOOL_PATH}/logs"
	if [ ! -d "${LOGS_DIR}" ]; then
		RUN_CMD="mkdir -p ${LOGS_DIR}"; runLogCMD "${RUN_CMD}"
	fi

	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		DOCKER_DIR="${WORK_DIR}/docker_scan"
		if [ ! -d ${DOCKER_DIR} ]; then
			RUN_CMD="mkdir -p $DOCKER_DIR"; runLogCMD "${RUN_CMD}"
		fi

		VMM_TOOL_SCAN_DIR="${WORK_DIR}/VMM_Tool_scan"
		if [ ! -d ${VMM_TOOL_SCAN_DIR} ]; then
			RUN_CMD="mkdir -p $VMM_TOOL_SCAN_DIR"; runLogCMD "${RUN_CMD}"
		fi
		
		if [ "$VIRTUALIZATION_HOST_SCAN_ENABLED" = "true" ]; then
			VTECH_WORK_DIR="${WORK_DIR}/vtech"
			if [ ! -d ${VTECH_WORK_DIR} ]; then
				RUN_CMD="mkdir -p $VTECH_WORK_DIR"; runLogCMD "${RUN_CMD}"
			fi
			VTECH_OUTPUT_DIR="${VTECH_WORK_DIR}/output"
			if [ ! -d ${VTECH_OUTPUT_DIR} ]; then
				RUN_CMD="mkdir -p $VTECH_OUTPUT_DIR"; runLogCMD "${RUN_CMD}"
			fi			
		fi			
	fi
}

removeDirs()
{
	#on uninstall action do not remove files from configured PACKAGE_OUTPUT_DIR directory
	#as it is configured by customer (e.g. a shared drive) and we don't want to delete
	#any files from there (the behavior decided and agreed upon)
	
	RUN_CMD="rm -f ${FULL_TOOL_PATH}/config/successful_setup.info"; runLogCMD "${RUN_CMD}"
	
	PACKAGE_OUTPUT_DIR="${FULL_TOOL_PATH}/output"
	if [ -d ${PACKAGE_OUTPUT_DIR} ]; then
		RUN_CMD="rm -rf ${FULL_TOOL_PATH}/output"; runLogCMD "${RUN_CMD}"
	fi

	WORK_DIR="${FULL_TOOL_PATH}/work"
	if [ -d ${WORK_DIR} ]; then
		RUN_CMD="rm -rf ${FULL_TOOL_PATH}/work"; runLogCMD "${RUN_CMD}"
	fi

	TEMP_DIR="${FULL_TOOL_PATH}/tempdir"
	if [ -d ${TEMP_DIR} ]; then
		RUN_CMD="rm -rf ${FULL_TOOL_PATH}/tempdir"; runLogCMD "${RUN_CMD}"
	fi

	# remove logs directory as the last one, runCMDOnly used instead of runLogCMD as this would try to log to log.txt, which is being removed
	LOGS_DIR="${FULL_TOOL_PATH}/logs"
	if [ -d ${LOGS_DIR} ]; then
		RUN_CMD="rm -rf ${FULL_TOOL_PATH}/logs"; runCMDOnly "${RUN_CMD}"
	fi

	if [ ! -d ${PACKAGE_OUTPUT_DIR} -a ! -d ${WORK_DIR} -a ! -d ${LOGS_DIR} -a ! -d ${TEMP_DIR} ]; then
		EC=0
	fi
}

# Runs CIT hardware or software scan and updates statistics (error codes and finish times)
runScan()
{
	# $1 - scan type, either SW or HW
	# $2 - scan type description, one of the names defined in "Names' definitions for all parts of software scan (type SW)" above
	# $3 - a prefix for updating scan statistics, see the same section above
	# $4 - a full CIT scan command to run, e.g. "$CIT_HOME/bin/wscanfs -s -c ${FULL_TOOL_PATH}/config/isotag_config.xml -i -o ${WORK_DIR}/isotag_scan.xml"

	SCAN_TYPE=$1
	SCAN_NAME=$2
	STAT_SCAN_LAST_PREFIX=$3
	RUN_CMD=$4

	printAndLogTxt "Starting $SCAN_NAME ($SCAN_TYPE)..."
	runLogCMDWithOutput "${RUN_CMD}"
	SCAN_STATUS=$EC

	updateOperationStats $SCAN_STATUS "$SCAN_NAME" "$STAT_SCAN_LAST_PREFIX"
	return $SCAN_STATUS
}

# Updates last operation status and times and print successful or error message (with an optional message if present) if OP_STATUS is non zero
updateOperationStats()
{
	OP_STATUS=$1
	OP_NAME=$2
	STAT_OP_LAST_PREFIX=$3
	OPTIONAL_ERR_MSG_TO_LOG=$4

	getTSUTC
	updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_OP_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}" $OP_STATUS
	updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_OP_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}" $TSUTC
	if [ $OP_STATUS -eq 0 ]; then
		printAndLogTxt "$OP_NAME was successful"
		updateValueInYml "${WORK_DIR}/scanner_status.yml" "${STAT_OP_LAST_PREFIX}${STAT_LAST_OK_TIME_SUFFIX}" $TSUTC
	else
		[ -n "$OPTIONAL_ERR_MSG_TO_LOG" ] && printAndLogTxt "$OPTIONAL_ERR_MSG_TO_LOG"
		printAndLogTxt "$OP_NAME failed - return code $OP_STATUS";
	fi
}

updateOperationStatsAndExit()
{
	updateOperationStats $1 "$2" "$3" "$4"
	exit $1
}

addScanSchedule()
{
	SCAN_NAME=$1
	EXECUTABLE_FULLPATH=$2
	SCAN_PERIOD=$3

	printAndLogTxt "Adding scheduled task for $SCAN_NAME"
	logTxt "Adding scheduled task $EXECUTABLE_FULLPATH with period $SCAN_PERIOD"

	RUN_CMD="(crontab -l 2>/dev/null | grep -v \"${EXECUTABLE_FULLPATH}\" ; echo '${SCAN_PERIOD} \"${EXECUTABLE_FULLPATH}\"')| (crontab 2>/dev/null || crontab -)"; runLogCMD "${RUN_CMD}";
	
	SCAN_PERIOD_STARS_ESCAPED=`echo "$SCAN_PERIOD" | sed 's#\*#\\\*#g'`
	RUN_CMD="crontab -l 2>/dev/null | grep '"$SCAN_PERIOD_STARS_ESCAPED" \"${EXECUTABLE_FULLPATH}\"' | wc -l"; runLogCMD "${RUN_CMD}"

	if [ "$CMD_OUTPUT" -eq 1 ]; then printAndLogTxt "$SCAN_NAME schedule added successfully"; else printAndLogTxtExit "Adding schedule for $SCAN_NAME failed"; fi
}

removeScanSchedule()
{
	SCAN_NAME=$1
	EXECUTABLE_FULLPATH=$2
	
	printAndLogTxt "Checking if $SCAN_NAME is scheduled"

	RUN_CMD="crontab -l 2>/dev/null | grep \"${EXECUTABLE_FULLPATH}\" | wc -l"; runLogCMD "${RUN_CMD}"
	if [ "$CMD_OUTPUT" -ne 0 ]; then
		printAndLogTxt "Removing scheduled task $EXECUTABLE_FULLPATH for $SCAN_NAME"
		RUN_CMD="crontab -l 2>/dev/null | grep -v \"${EXECUTABLE_FULLPATH}\" | (crontab 2>/dev/null || crontab -)"; runLogCMD "${RUN_CMD}"
		RUN_CMD="crontab -l 2>/dev/null | grep \"${EXECUTABLE_FULLPATH}\" | wc -l"; runLogCMD "${RUN_CMD}"
		if [ "$CMD_OUTPUT" -eq 0 ]; then printAndLogTxt "$SCAN_NAME schedule removed successfully"; else printAndLogTxt "WARNING: Removing schedule for $SCAN_TYPE_DESC failed"; fi
	fi
}

scheduleScans()
{

	if [ -n "$SW_SCAN_HOUR" ]; then
		HOUR=$SW_SCAN_HOUR
	else
		HOUR=`date +%H`
	fi

	if [ -n "$SW_SCAN_MINUTE" ]; then
		MINUTE=`expr $SW_SCAN_MINUTE - 2`
		if [ $MINUTE -lt 0 ]; then
			MINUTE=`expr $MINUTE + 60`
			HOUR=`expr $HOUR - 1`
			if [ $HOUR -lt 0 ]; then
				HOUR=`expr $HOUR + 24`
			fi
		fi		
	else
		MINUTE=`date +%M`
	fi

	# add HW scan scheduling
	if $HW_SCAN_SCHEDULE_ENABLED; then
		MINUTE_HW1=$MINUTE			
		if [ $MINUTE_HW1 -gt 29 ]; then
			MINUTE_HW2=`expr $MINUTE_HW1 - 30`
			MINUTES_HW="$MINUTE_HW2,$MINUTE_HW1"
		else
			MINUTE_HW2=`expr $MINUTE_HW1 + 30`
			MINUTES_HW="$MINUTE_HW1,$MINUTE_HW2"
		fi

		#MINUTES_HW is e.g. 17,47 to run HW scan at 17th and 47th minute of an hour
		SCAN_PERIOD="$MINUTES_HW * * * *"
		addScanSchedule "$HW_SCAN_NAME" "$HW_SCAN_CRON_LINK_PATH" "$SCAN_PERIOD"
	fi
	
	if [ -n "$SW_SCAN_DAY_OF_WEEK" ]; then
		DAY_OF_WEEK=$SW_SCAN_DAY_OF_WEEK
	else
		DAY_OF_WEEK=`date +%w`
	fi
	
	# add SW scan scheduling
	if $SW_SCAN_SCHEDULE_ENABLED; then
		HOUR_SW=$HOUR
		MINUTE_SW=`expr $MINUTE + 2`			
		if [ $MINUTE_SW -gt 59 ]; then
			MINUTE_SW=`expr $MINUTE_SW - 60`
			HOUR_SW=`expr $HOUR_SW + 1`
			if [ $HOUR_SW -gt 23 ]; then
				HOUR_SW=`expr $HOUR_SW - 24`
				DAY_OF_WEEK=`expr $DAY_OF_WEEK + 1`
				if [ $DAY_OF_WEEK -gt 6 ]; then
					DAY_OF_WEEK=`expr $DAY_OF_WEEK - 7`
				fi
			fi
		fi

		if [ $SW_SCAN_FREQUENCY = "weekly" ]; then
			SCAN_PERIOD="$MINUTE_SW $HOUR_SW * * $DAY_OF_WEEK"
		elif [ $SW_SCAN_FREQUENCY = "daily" ]; then
			SCAN_PERIOD="$MINUTE_SW $HOUR_SW * * *"
		else
			printAndLogTxtExit "Scheduling SW scans failed - Invalid SW_SCAN_FREQUENCY value ($SW_SCAN_FREQUENCY)"
		fi

		
		if [ -z "$LMT_SERVER_URL" -a -z "$LMT_SERVER_API_TOKEN" ];
			then
				addScanSchedule "$SW_SCAN_NAME" "$SW_SCAN_CRON_LINK_PATH" "$SCAN_PERIOD"
			else	
				addScanSchedule "$SW_SCAN_AND_UPLOAD_RESULTS_NAME" "$SW_SCAN_AND_UPLOAD_CRON_LINK_PATH" "$SCAN_PERIOD"
			fi
	fi

	# add pack and upload results scheduling
	if $DAILY_PACK_RESULTS_CREATION_ENABLED; 
		then
			HOUR_PK=$HOUR
			MINUTE_PK=`expr $MINUTE - 15`		
			if [ $MINUTE_PK -lt 0 ]; then
				MINUTE_PK=`expr $MINUTE_PK + 60`
				HOUR_PK=`expr $HOUR_PK - 1`
				if [ $HOUR_PK -lt 0 ]; then
					HOUR_PK=`expr $HOUR_PK + 24`
				fi
			fi
			PACK_PERIOD="$MINUTE_PK $HOUR_PK * * *"
			if [ -z "$LMT_SERVER_URL" ] && [ -z "$LMT_SERVER_API_TOKEN" ]; 
			then
				addScanSchedule "$PACK_RESULTS_NAME" "$PACK_RESULTS_CRON_LINK_PATH" "$PACK_PERIOD"
			else	
				addScanSchedule "$PACK_AND_UPLOAD_RESULTS_NAME" "$PACK_AND_UPLOAD_RESULTS_CRON_LINK_PATH" "$PACK_PERIOD"
			fi
	fi
}

logScanSchedule()
{
	if [ "$HW_SCAN_SCHEDULE_ENABLED" = "true" -o "$SW_SCAN_SCHEDULE_ENABLED" = "true" ]; then
		logTxt "Current crontab contents:"
		RUN_CMD="crontab -l 2>/dev/null"; runLogCMDWithOutput "${RUN_CMD}"
	fi
}

checkSoftwareCatalog()
{
	if $CATALOG_SCAN_ENABLED; then
		if [ ! -f "$CIT_CATALOG_PATH" ]; then
			printAndLogTxtExit "Catalog file $CIT_CATALOG_PATH not found. Please, copy the catalog file to $FULL_TOOL_PATH/config directory"
		fi
	fi
}

setupConfigParameters()
{
	printAndLogTxt "Initializing configuration parameters of Disconnected Scanner"

	#Check if setup_config.ini exists
	if [ ! -f $DSCANNER_CONFIG ]; then
		printAndLogTxtExit "$DSCANNER_CONFIG not found"
	fi

	. "$DSCANNER_CONFIG"

	# mandatory parameters which must exist in setup_config.ini
	if [ ! -n "$PACKAGE_OUTPUT_DIR" ]; then
		printAndLogTxtExit "Mandatory parameter PACKAGE_OUTPUT_DIR is not set - set a correct path in $DSCANNER_CONFIG"
	fi

	# setting defaults for parameters, which should exist in setup_config.ini
	# and normalize the values that are set by changing all to lowercase
	if echo "$HW_SCAN_SCHEDULE_ENABLED" | grep -i "^true$" > /dev/null; then
		HW_SCAN_SCHEDULE_ENABLED=true
	elif echo "$HW_SCAN_SCHEDULE_ENABLED" | grep -i "^false$" > /dev/null; then
		HW_SCAN_SCHEDULE_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		printAndLogTxt "WARNING: Incorrect value of HW_SCAN_SCHEDULE_ENABLED parameter: '$HW_SCAN_SCHEDULE_ENABLED' in $DSCANNER_CONFIG, using default: true"
		HW_SCAN_SCHEDULE_ENABLED=true
	fi
	
	if echo "$DAILY_PACK_RESULTS_CREATION_ENABLED" | grep -i "^true$" > /dev/null; then
		DAILY_PACK_RESULTS_CREATION_ENABLED=true
	elif echo "$DAILY_PACK_RESULTS_CREATION_ENABLED" | grep -i "^false$" > /dev/null; then
		DAILY_PACK_RESULTS_CREATION_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		printAndLogTxt "WARNING: Incorrect value of DAILY_PACK_RESULTS_CREATION_ENABLED parameter: '$DAILY_PACK_RESULTS_CREATION_ENABLED' in $DSCANNER_CONFIG, using default: true"
		DAILY_PACK_RESULTS_CREATION_ENABLED=true
	fi
	
	if echo "$SW_SCAN_SCHEDULE_ENABLED" | grep -i "^true$" > /dev/null; then
		SW_SCAN_SCHEDULE_ENABLED=true
	elif echo "$SW_SCAN_SCHEDULE_ENABLED" | grep -i "^false$" > /dev/null; then
		SW_SCAN_SCHEDULE_ENABLED=false
	else
		printAndLogTxt "WARNING: Incorrect value of SW_SCAN_SCHEDULE_ENABLED parameter: '$SW_SCAN_SCHEDULE_ENABLED' in $DSCANNER_CONFIG, using default: false"
		SW_SCAN_SCHEDULE_ENABLED=false
	fi

	if echo "$SW_SCAN_FREQUENCY" | grep -i "^weekly$" > /dev/null; then
		SW_SCAN_FREQUENCY=weekly
	elif echo "$SW_SCAN_FREQUENCY" | grep -i "^daily$" > /dev/null; then
		SW_SCAN_FREQUENCY=daily
	else
		printAndLogTxt "WARNING: Incorrect value of SW_SCAN_FREQUENCY parameter: '$SW_SCAN_FREQUENCY' in $DSCANNER_CONFIG, using default: weekly"
		SW_SCAN_FREQUENCY=weekly
	fi

	if [ -n "$SW_SCAN_DAY_OF_WEEK" ]; then
		if echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^sun$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=0
		elif echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^mon$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=1
		elif echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^tue$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=2
		elif echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^wed$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=3
		elif echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^thu$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=4
		elif echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^fri$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=5
		elif echo "$SW_SCAN_DAY_OF_WEEK" | grep -i "^sat$" > /dev/null; then
			SW_SCAN_DAY_OF_WEEK=6		
		else
			printAndLogTxt "WARNING: Incorrect value of SW_SCAN_DAY_OF_WEEK parameter: '$SW_SCAN_DAY_OF_WEEK' in $DSCANNER_CONFIG, using default: EMPTY"
			SW_SCAN_DAY_OF_WEEK=
		fi
	fi
	
	if [ -n "$SW_SCAN_LOCAL_TIME" ]; then
		if echo "$SW_SCAN_LOCAL_TIME" | grep '^[0-9]*:[0-9]*$' > /dev/null; then
			SW_SCAN_LOCAL_TIME_HOUR=`echo "$SW_SCAN_LOCAL_TIME" | cut -d ":" -f 1`
			SW_SCAN_LOCAL_TIME_MINUTE=`echo "$SW_SCAN_LOCAL_TIME" | cut -d ":" -f 2`
			if [ "$SW_SCAN_LOCAL_TIME_HOUR" -ge 0 ] 2>/dev/null && [ "$SW_SCAN_LOCAL_TIME_HOUR" -le 23 ] 2>/dev/null && [ "$SW_SCAN_LOCAL_TIME_MINUTE" -ge 0 ] 2>/dev/null && [ "$SW_SCAN_LOCAL_TIME_MINUTE" -le 59 ] 2>/dev/null; then
				SW_SCAN_HOUR=$SW_SCAN_LOCAL_TIME_HOUR
				SW_SCAN_MINUTE=$SW_SCAN_LOCAL_TIME_MINUTE		
			else
				printAndLogTxt "WARNING: Incorrect value of SW_SCAN_LOCAL_TIME parameter: '$SW_SCAN_LOCAL_TIME' in $DSCANNER_CONFIG, using default: EMPTY"
			fi
		else
			printAndLogTxt "WARNING: Incorrect value of SW_SCAN_LOCAL_TIME parameter: '$SW_SCAN_LOCAL_TIME' in $DSCANNER_CONFIG, using default: EMPTY"
		fi
	fi
	
	if [ -n "$SW_SCAN_CPU_THRESHOLD_PERCENTAGE" ]; then
		# if the command returns value other than 0 then commands in the curly brackets will be executed
		# this syntax is used because it works on every platform (including Solaris 10)
		echo "$SW_SCAN_CPU_THRESHOLD_PERCENTAGE" | grep -i "^[0-9]*$" > /dev/null &&
		[ "$SW_SCAN_CPU_THRESHOLD_PERCENTAGE" -ge 5 ] 2>/dev/null && [ "$SW_SCAN_CPU_THRESHOLD_PERCENTAGE" -le 100 ] 2>/dev/null ||
		{
			# the parameter has either incorrect format or incorrect value
			printAndLogTxtExit "Incorrect value of SW_SCAN_CPU_THRESHOLD_PERCENTAGE parameter: '$SW_SCAN_CPU_THRESHOLD_PERCENTAGE' - set a correct value in $DSCANNER_CONFIG" 100
		}
	fi

	# setting defaults for not visible internal parameters, which can be set in setup_config.ini
	# and normalize the values that are set by changing all to lowercase
	
	if echo "$ALLOW_SIMULTANEOUS_SCAN_EXECUTION" | grep -i "^true$" > /dev/null; then
		ALLOW_SIMULTANEOUS_SCAN_EXECUTION=true
	elif echo "$ALLOW_SIMULTANEOUS_SCAN_EXECUTION" | grep -i "^false$" > /dev/null; then
		ALLOW_SIMULTANEOUS_SCAN_EXECUTION=false
	else
		# the parameter either not set or incorrect value - using default
		ALLOW_SIMULTANEOUS_SCAN_EXECUTION=false
	fi
	
	if echo "$CATALOG_SCAN_ENABLED" | grep -i "^true$" > /dev/null; then
		CATALOG_SCAN_ENABLED=true
	elif echo "$CATALOG_SCAN_ENABLED" | grep -i "^false$" > /dev/null; then
		CATALOG_SCAN_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		CATALOG_SCAN_ENABLED=true
	fi

	if echo "$ISOTAG_SCAN_ENABLED" | grep -i "^true$" > /dev/null; then
		ISOTAG_SCAN_ENABLED=true
	elif echo "$ISOTAG_SCAN_ENABLED" | grep -i "^false$" > /dev/null; then
		ISOTAG_SCAN_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		ISOTAG_SCAN_ENABLED=true
	fi
	
	if echo "$SLMTAG_SCAN_ENABLED" | grep -i "^true$" > /dev/null; then
		SLMTAG_SCAN_ENABLED=true
	elif echo "$SLMTAG_SCAN_ENABLED" | grep -i "^false$" > /dev/null; then
		SLMTAG_SCAN_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		SLMTAG_SCAN_ENABLED=true
	fi

	if echo "$PACKAGE_SCAN_ENABLED" | grep -i "^true$" > /dev/null; then
		PACKAGE_SCAN_ENABLED=true
	elif echo "$PACKAGE_SCAN_ENABLED" | grep -i "^false$" > /dev/null; then
		PACKAGE_SCAN_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		PACKAGE_SCAN_ENABLED=true
	fi
	
	if echo "$ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION" | grep -i "^true$" > /dev/null; then
		ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION=true
	elif echo "$ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION" | grep -i "^false$" > /dev/null; then
		ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION=false
	else
		# the parameter either not set or incorrect value - using default
		ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION=false
	fi	
	
	# if the command returns value other than 0 then commands in the curly brackets will be executed
	# this syntax is used because it works on every platform (including Solaris 10)
	echo "$NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP" | grep -i "^[0-9]*$" > /dev/null ||
	{
		# the parameter either not set or incorrect value - using default
		printAndLogTxt "WARNING: Incorrect value of NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP parameter: '$NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP' in $DSCANNER_CONFIG, using default: 20"
		NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP=20
	}

	if echo "$ENDPOINT_ID_REGENERATION_ENABLED" | grep -i "^true$" > /dev/null; then
		ENDPOINT_ID_REGENERATION_ENABLED=true
	elif echo "$ENDPOINT_ID_REGENERATION_ENABLED" | grep -i "^false$" > /dev/null; then
		ENDPOINT_ID_REGENERATION_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		ENDPOINT_ID_REGENERATION_ENABLED=false
	fi
	
	# Docker scan related variables
	if echo "$DOCKER_SCAN_ENABLED" | grep -i "^true$" > /dev/null; then
		DOCKER_SCAN_ENABLED=true
	elif echo "$DOCKER_SCAN_ENABLED" | grep -i "^false$" > /dev/null; then
		DOCKER_SCAN_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		DOCKER_SCAN_ENABLED=false
	fi
	
	if echo "$FAIL_ON_MISSING_CAPACITY_SCAN" | grep -i "^true$" > /dev/null; then
		FAIL_ON_MISSING_CAPACITY_SCAN=true
	elif echo "$FAIL_ON_MISSING_CAPACITY_SCAN" | grep -i "^false$" > /dev/null; then
		FAIL_ON_MISSING_CAPACITY_SCAN=false
	else
		# the parameter either not set or incorrect value - using default
		FAIL_ON_MISSING_CAPACITY_SCAN=false
	fi

	# check if customer docker path is set
	if [ -n "${DOCKER_EXEC}" ];
	then
		DOCKER_CMD="${DOCKER_EXEC}"
		logTxt "DOCKER_EXEC is set, using $DOCKER_EXEC as the new docker command"
		
	fi
	# check if additional docker options are set
	[ -n "${DOCKER_OPTS}" ] && logTxt "Using DOCKER_OPTS = ${DOCKER_OPTS}"

	# if the command returns value other than 0 then commands in the curly brackets will be executed
	# this syntax is used because it works on every platform (including Solaris 10)
	echo "$MAX_HW_SCAN_DAYS" | grep -i "^[0-9]*$" > /dev/null ||
	{
		# the parameter either not set or incorrect value - using default
		printAndLogTxt "WARNING: Incorrect value of MAX_HW_SCAN_DAYS parameter: '$MAX_HW_SCAN_DAYS' in $DSCANNER_CONFIG, using default: 14"
		MAX_HW_SCAN_DAYS=14
	}

	# if the command returns value other than 0 then commands in the curly brackets will be executed
	# this syntax is used because it works on every platform (including Solaris 10)
	echo "$MAX_HW_SCAN_FILES" | grep -i "^[0-9]*$" > /dev/null ||
	{
		# the parameter either not set or incorrect value - using default
		printAndLogTxt "WARNING: Incorrect value of MAX_HW_SCAN_FILES parameter: '$MAX_HW_SCAN_FILES' in $DSCANNER_CONFIG, using default: 7"
		MAX_HW_SCAN_FILES=7
	}

	# check if public cloud type is set and if it's a valid value for the current OS
	if [ "$PUBLIC_CLOUD_TYPE" != "" ]; then
		if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
			UNAME_MACHINE=`uname -m`
			# this covers x86 architectures
			if [ "$UNAME_MACHINE" = "x86_64" -o "`echo ${UNAME_MACHINE} | grep -i "^i[0-9]86$"`" != "" ]; then
				if [ "$PUBLIC_CLOUD_TYPE" != "$CPT_IBM_SOFTLAYER" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_MS_AZURE" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_AMAZON_EC2" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_GOOGLE_CLOUD" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_ORACLE_CLOUD" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_ALIBABA_CLOUD" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_TENCENT_CLOUD" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_NEC_CLOUD" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_FUJITSU_CLOUD" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_NTT_ECL" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_NTT_VMWARE" -a "$PUBLIC_CLOUD_TYPE" != "$CPT_KDDI_VS" ]; then
					printAndLogTxt "WARNING: Incorrect value of PUBLIC_CLOUD_TYPE parameter: '$PUBLIC_CLOUD_TYPE' in $DSCANNER_CONFIG. Supported values for this platform are: '$CPT_IBM_SOFTLAYER', '$CPT_MS_AZURE', '$CPT_AMAZON_EC2', '$CPT_GOOGLE_CLOUD', '$CPT_ORACLE_CLOUD', '$CPT_ALIBABA_CLOUD', '$CPT_TENCENT_CLOUD', '$CPT_NEC_CLOUD', '$CPT_FUJITSU_CLOUD', '$CPT_NTT_ECL', '$CPT_NTT_VMWARE', '$CPT_KDDI_VS'. Reseting the value to empty string."
					PUBLIC_CLOUD_TYPE=""
				fi
			# this covers both ppc64 and ppc64le architectures
			elif [ `echo ${UNAME_MACHINE} | grep -i "ppc64"` ]; then
				if [ "$PUBLIC_CLOUD_TYPE" != "$CPT_IBM_POWER" ]; then
					printAndLogTxt "WARNING: Incorrect value of PUBLIC_CLOUD_TYPE parameter: '$PUBLIC_CLOUD_TYPE' in $DSCANNER_CONFIG. Supported values for this platform are: '$CPT_IBM_POWER'. Reseting the value to empty string."
					PUBLIC_CLOUD_TYPE=""
				fi
			# this covers both s390 and s390x architectures
			elif [ `echo ${UNAME_MACHINE} | grep -i "s390"` ]; then
				if [ "$PUBLIC_CLOUD_TYPE" != "$CPT_IBM_CLOUD_LINUXONE" ]; then
					printAndLogTxt "WARNING: Incorrect value of PUBLIC_CLOUD_TYPE parameter: '$PUBLIC_CLOUD_TYPE' in $DSCANNER_CONFIG. Supported values for this platform are: '$CPT_IBM_CLOUD_LINUXONE'. Reseting the value to empty string."
					PUBLIC_CLOUD_TYPE=""
				fi
			else
				printAndLogTxt "WARNING: PUBLIC_CLOUD_TYPE='$PUBLIC_CLOUD_TYPE' in $DSCANNER_CONFIG is not supported for '${UNAME_MACHINE}' architecture. Reseting the value to empty string."
				PUBLIC_CLOUD_TYPE=""
			fi
		elif [ "$OS_NAME" = "$OS_NAME_AIX" ]; then
			if [ "$PUBLIC_CLOUD_TYPE" != "$CPT_IBM_POWER" ]; then
				printAndLogTxt "WARNING: Incorrect value of PUBLIC_CLOUD_TYPE parameter: '$PUBLIC_CLOUD_TYPE' in $DSCANNER_CONFIG. Supported values for this platform are: '$CPT_IBM_POWER'. Reseting the value to empty string."
				PUBLIC_CLOUD_TYPE=""
			fi
		else
			printAndLogTxt "WARNING: PUBLIC_CLOUD_TYPE='$PUBLIC_CLOUD_TYPE' in $DSCANNER_CONFIG is not supported for '${OS_NAME}' operating system. Reseting the value to empty string."
			PUBLIC_CLOUD_TYPE=""
		fi
		
		[ -n "${PUBLIC_CLOUD_TYPE}" ] && logTxt "Using PUBLIC_CLOUD_TYPE = ${PUBLIC_CLOUD_TYPE}"
	fi
	
	# check if VIRTUALIZATION_HOST_SCAN_ENABLED is enabled and if it's check whether it is supported for current OS
	if echo "$VIRTUALIZATION_HOST_SCAN_ENABLED" | grep -i "^true$" > /dev/null; then
		if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
			if ! [ -x "$(command -v virsh)" -o -x "$(command -v xl)" ]; then 
				printAndLogTxt "WARNING: VIRTUALIZATION_HOST_SCAN_ENABLED in enabled but neither 'virsh' nor 'xl' command is available on the system. Reseting the value to false."
				VIRTUALIZATION_HOST_SCAN_ENABLED=false
			else
				if ! [ -x "$(command -v /bin/bash)" ]; then
					printAndLogTxt "WARNING: VIRTUALIZATION_HOST_SCAN_ENABLED in enabled but bash shell is not available on the system. Reseting the value to false."
					VIRTUALIZATION_HOST_SCAN_ENABLED=false					
				else
					if ! [ -x "$(command -v xmllint)" ]; then
						printAndLogTxt "WARNING: VIRTUALIZATION_HOST_SCAN_ENABLED in enabled but 'xmllint' command is not available on the system. Reseting the value to false."
						VIRTUALIZATION_HOST_SCAN_ENABLED=false
					else
						UNAME_MACHINE=`uname -m`
						# this covers x86 architectures
						if [ "$UNAME_MACHINE" = "x86_64" -o "`echo ${UNAME_MACHINE} | grep -i "^i[0-9]86$"`" != "" ]; then
							VIRTUALIZATION_HOST_SCAN_ENABLED=true
						# this covers both ppc64 and ppc64le architectures
						elif [ `echo ${UNAME_MACHINE} | grep -i "ppc64"` ]; then
							VIRTUALIZATION_HOST_SCAN_ENABLED=true
						else
							printAndLogTxt "WARNING: VIRTUALIZATION_HOST_SCAN_ENABLED in $DSCANNER_CONFIG is not supported for '${UNAME_MACHINE}' architecture. Reseting the value to empty string."
							VIRTUALIZATION_HOST_SCAN_ENABLED=false
						fi					
					fi
				fi			
			fi			
		else
			printAndLogTxt "WARNING: VIRTUALIZATION_HOST_SCAN_ENABLED in $DSCANNER_CONFIG is not supported for '${OS_NAME}' operating system. Reseting the value to false."
			VIRTUALIZATION_HOST_SCAN_ENABLED=false
		fi	
		VIRTUALIZATION_HOST_SCAN_ENABLED=true
	elif echo "$VIRTUALIZATION_HOST_SCAN_ENABLED" | grep -i "^false$" > /dev/null; then
		VIRTUALIZATION_HOST_SCAN_ENABLED=false
	else
		# the parameter either not set or incorrect value - using default
		VIRTUALIZATION_HOST_SCAN_ENABLED=false
	fi
	
	# only if VIRTUALIZATION_HOST_SCAN_ENABLED is enabled check if additional COLLECT_HOST_HOSTNAME option is set
	if [ "$VIRTUALIZATION_HOST_SCAN_ENABLED" = "true" ]; then
		if echo "$COLLECT_HOST_HOSTNAME" | grep -i "^true$" > /dev/null; then
			COLLECT_HOST_HOSTNAME=true
		elif echo "$COLLECT_HOST_HOSTNAME" | grep -i "^false$" > /dev/null; then
			COLLECT_HOST_HOSTNAME=false
		else
			# the parameter either not set or incorrect value - using default
			COLLECT_HOST_HOSTNAME=false
		fi	
	fi
	
	# set default values for CURL parameters if empty
	if [ -z "$CURL_PARAMETERS" ];
		then
		CURL_PARAMETERS="-k -s"
	fi
	
	if [ -z "$CURL_PATH" ];
		then
		CURL_PATH="curl"
	fi
	
}

logConfigParameters()
{
	# PUT here parameters that ARE in setup_config.ini by default:
	logTxt "$DSCANNER_CONFIG parameters values:"
	logTxtCont "SW_SCAN_SCHEDULE_ENABLED=${SW_SCAN_SCHEDULE_ENABLED}"
	logTxtCont "SW_SCAN_FREQUENCY=${SW_SCAN_FREQUENCY}"
	[ -n "${SW_SCAN_DAY_OF_WEEK}" ] && logTxtCont "SW_SCAN_DAY_OF_WEEK=${SW_SCAN_DAY_OF_WEEK}"
	[ -n "${SW_SCAN_LOCAL_TIME}" ] && logTxtCont "SW_SCAN_LOCAL_TIME=${SW_SCAN_LOCAL_TIME}"
	[ -n "${SW_SCAN_CPU_THRESHOLD_PERCENTAGE}" ] && logTxtCont "SW_SCAN_CPU_THRESHOLD_PERCENTAGE=${SW_SCAN_CPU_THRESHOLD_PERCENTAGE}"
	logTxtCont "HW_SCAN_SCHEDULE_ENABLED=${HW_SCAN_SCHEDULE_ENABLED}"
	logTxtCont "DAILY_PACK_RESULTS_CREATION_ENABLED=${DAILY_PACK_RESULTS_CREATION_ENABLED}"
	logTxtCont "PACKAGE_OUTPUT_DIR=${PACKAGE_OUTPUT_DIR}"
	logTxtCont "MAX_HW_SCAN_DAYS=${MAX_HW_SCAN_DAYS}"
	logTxtCont "MAX_HW_SCAN_FILES=${MAX_HW_SCAN_FILES}"
	logTxtCont "NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP=${NUMBER_OF_HISTORICAL_RESULTS_TO_KEEP}"
	logTxtCont "LMT_SERVER_URL=${LMT_SERVER_URL}"
	logTxtCont "LMT_SERVER_API_TOKEN=${LMT_SERVER_API_TOKEN}"
	logTxtCont "CURL_PARAMETERS=${CURL_PARAMETERS}"
	logTxtCont "CURL_PATH=${CURL_PATH}"
	
	[ -n "${PUBLIC_CLOUD_TYPE}" ] && logTxtCont "PUBLIC_CLOUD_TYPE=${PUBLIC_CLOUD_TYPE}"

	# PUT here parameters that DO NOT EXIST in setup_config.ini by default:
	logTxt "$DSCANNER_CONFIG INTERNAL parameters values:"
	logTxtCont "CATALOG_SCAN_ENABLED=${CATALOG_SCAN_ENABLED}"
	logTxtCont "ISOTAG_SCAN_ENABLED=${ISOTAG_SCAN_ENABLED}"
	logTxtCont "PACKAGE_SCAN_ENABLED=${PACKAGE_SCAN_ENABLED}"
	[ -n "${DATASOURCE_NAME}" ] && logTxtCont "DATASOURCE_NAME=${DATASOURCE_NAME}"
	[ -n "${ALLOW_SIMULTANEOUS_SCAN_EXECUTION}" ] && logTxtCont "ALLOW_SIMULTANEOUS_SCAN_EXECUTION=${ALLOW_SIMULTANEOUS_SCAN_EXECUTION}"
		
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		logTxtCont "DOCKER_SCAN_ENABLED=${DOCKER_SCAN_ENABLED}"
		logTxtCont "ENDPOINT_ID_REGENERATION_ENABLED=${ENDPOINT_ID_REGENERATION_ENABLED}"
		logTxtCont "FAIL_ON_MISSING_CAPACITY_SCAN=${FAIL_ON_MISSING_CAPACITY_SCAN}"
		logTxtCont "VIRTUALIZATION_HOST_SCAN_ENABLED=${VIRTUALIZATION_HOST_SCAN_ENABLED}"
		logTxtCont "COLLECT_HOST_HOSTNAME=${COLLECT_HOST_HOSTNAME}"
		
		[ -n "${DOCKER_EXEC}" ] && logTxtCont "DOCKER_EXEC=${DOCKER_EXEC}"
		[ -n "${DOCKER_OPTS}" ] && logTxtCont "DOCKER_OPTS=${DOCKER_OPTS}"
	fi
}

setGrepCmd()
{
	type egrep > /dev/null
	if [ $? -eq 0 ]; then
		GREP_CMD=egrep
	else
		GREP_CMD="grep -E"
	fi
}

isValidLocale()
{
	if [ "`locale 2>/dev/null | $GREP_CMD -i 'LANG=.*(utf8|utf-8)\"?$' | wc -l`" -eq 0 ]; then
		logTxt "Non utf-8 locale detected (LANG variable)"
	elif [ "`locale  2>/dev/null | $GREP_CMD -i 'LC_CTYPE=.*(utf8|utf-8)\"?$' | wc -l`" -eq 0 ]; then
		logTxt "Non utf-8 locale detected (LC_CTYPE variable)"
	else
		return 0
	fi
	return 1
}

switchLocale()
{
	NEW_LOCALE=`locale -a | $GREP_CMD -i '.*(utf8|utf-8)$' | head -n1`
	[ -z "$NEW_LOCALE" ] && NEW_LOCALE=C
	logTxt "Switching to one of utf-8 locales (safer option): $NEW_LOCALE"
	LC_ALL=$NEW_LOCALE
	LANG=$NEW_LOCALE
	export LC_ALL LANG
	logTxt "Locale set to:"
	runLogCMDWithOutput locale
}

suppressMsgForCronJob()
{
	if [ `echo $0 | grep _CRON.sh | wc -l` -eq 1 ]; then
		# Running as a cron job
		SUPPRESS_OUTPUT=true
	fi
}

generateCronLinks()
{
	deleteCronLinks
	RUN_CMD="ln -s ${SW_SCAN_FULLPATH} ${SW_SCAN_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="ln -s ${HW_SCAN_FULLPATH} ${HW_SCAN_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="ln -s ${PACK_RESULTS_FULL_PATH} ${PACK_RESULTS_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="ln -s ${PACK_AND_UPLOAD_RESULTS_FULL_PATH} ${PACK_AND_UPLOAD_RESULTS_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="ln -s ${SW_SCAN_AND_UPLOAD_FULLPATH} ${SW_SCAN_AND_UPLOAD_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
}

deleteCronLinks()
{
	RUN_CMD="rm -f ${SW_SCAN_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="rm -f ${HW_SCAN_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="rm -f ${PACK_RESULTS_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="rm -f ${PACK_AND_UPLOAD_RESULTS_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
	RUN_CMD="rm -f ${SW_SCAN_AND_UPLOAD_CRON_LINK_PATH}"; runLogCMD "${RUN_CMD}"
}

upgradeScanConfigFiles()
{
	upgradeConfigFileToLatestVersion "${FULL_TOOL_PATH}/config/isotag_config.xml" file
	upgradeConfigFileToLatestVersion "${FULL_TOOL_PATH}/config/slmtag_config.xml" file
	upgradeConfigFileToLatestVersion "${FULL_TOOL_PATH}/config/sw_config.xml" catalog	
}

upgradeConfigFileToLatestVersion()
{
	# $1 - cit scan config file
	# $2 - config format, either: 'file' or 'catalog'

	if [ -f "$1" ]; then
		printAndLogTxt "Upgrading $1 config file..."

		# fix missing newline at EOF issue in slmtag_config.xml from 9.2.22:
		if [ "`tail -1c "$1"`" != "" ]; then
			echo '' >> "$1"
		fi

		if [ "$2" = "file" ]; then
			if [ `cat "$1" | grep "Provider value" | grep \"provider_cache\" | wc -l` -ne 0 ]; then
				RUN_CMD="cat \"$1\" | sed \"s/<Provider value.*\\/>/<Provider value=\\\"provider_cache2\\\"\/>/\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
				RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
			fi
			RUN_CMD="rm -f \"$1.tmp_part\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="touch \"$1.tmp_part\""; runLogCMD "${RUN_CMD}"
			anyChange=0
			if [ `cat "$1" | grep "<ExtensionToCache" | grep \"*.swidtag\" | wc -l` -eq 0 ]; then
				RUN_CMD="echo \"<ExtensionToCache value=\\\"*.swidtag\\\"/>\" >> \"$1.tmp_part\" "; runLogCMD "${RUN_CMD}"
				anyChange=1
			fi
			if [ `cat "$1" | grep "<ExtensionToCache" | grep \"*.slmtag\" | wc -l` -eq 0 ]; then
				RUN_CMD="echo \"<ExtensionToCache value=\\\"*.slmtag\\\"/>\" >> \"$1.tmp_part\" "; runLogCMD "${RUN_CMD}"
				anyChange=1
			fi
			
			# in scan configs for wscanfs the sequence of fields matters (see citcli.xsd), ExtensionToCache goes after FileMask, so find the last one and then append
			if [ $anyChange -eq 1 ]; then
				# find LAST FileMask xml element and remove beginning and closing xml tags as they cause issues later on (redirection)
				RUN_CMD="grep FileMask $1 | tail -1 | tr -d '<' | tr -d '/>' | tr -d '\\n' | tr -d '\\r'"; runLogCMD "${RUN_CMD}"
				# escape star(*), dot(.) with slashes, so that they are not treated as regexps and quotation marks(") so that they are properly matched later on
				lastFileMaskAttr=`echo $CMD_OUTPUT | sed -e 's/\./\\\\\./g' | sed -e 's/\*/\\\\\*/g' | sed -e 's/\"/\\\\\"/g'`
				if [ "$lastFileMaskAttr" != "" ]; then 
					RUN_CMD="sed \"/${lastFileMaskAttr}/ r \"$1.tmp_part\"\" \"$1\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
					RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
				else
					printAndLogTxt "Could not find FileMask xml element in $1 config file. ExtensionToCache settings NOT added."
				fi
			fi
			RUN_CMD="rm -f \"$1.tmp_part\""; runLogCMD "${RUN_CMD}"
		fi

		if [ "$2" = "catalog" ]; then
			if [ `cat "$1" | grep "Attribute name=\"provider\"" | grep \"provider_cache\" | wc -l` -ne 0 ]; then
				RUN_CMD="cat \"$1\" | sed \"s/<Attribute name=\\\"provider\\\".*\\/>/<Attribute name=\\\"provider\\\" value=\\\"provider_cache2\\\"\/>/\"  > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
				RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
			fi
			RUN_CMD="rm -f \"$1.tmp_part\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="touch \"$1.tmp_part\""; runLogCMD "${RUN_CMD}"
			anyChange=0
			if [ `cat "$1" | grep "Attribute name=\"extensionToCache\"" | grep \"*.swidtag\" | wc -l` -eq 0 ]; then
				RUN_CMD="echo \"<Attribute name=\\\"extensionToCache\\\" value=\\\"*.swidtag\\\"/>\" >> \"$1.tmp_part\" "; runLogCMD "${RUN_CMD}"
				anyChange=1
			fi
			if [ `cat "$1" | grep "Attribute name=\"extensionToCache\"" | grep \"*.slmtag\" | wc -l` -eq 0 ]; then
				RUN_CMD="echo \"<Attribute name=\\\"extensionToCache\\\" value=\\\"*.slmtag\\\"/>\" >> \"$1.tmp_part\" "; runLogCMD "${RUN_CMD}"
				anyChange=1
			fi
			if [ $anyChange -eq 1 ]; then
				RUN_CMD="sed \"/Attribute name=\\\"provider\\\"/ r \"$1.tmp_part\"\" \"$1\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
				RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
			fi
			RUN_CMD="rm -f \"$1.tmp_part\""; runLogCMD "${RUN_CMD}"
		fi

	fi
}

updateParametersInConfigFiles()
{
	if [ -n "$SW_SCAN_CPU_THRESHOLD_PERCENTAGE" ]; then
		cpuThreshold=""
		
		if [ "$SW_SCAN_CPU_THRESHOLD_PERCENTAGE" -lt 100 ]; then
			cpuTresholdPercentageWork=`expr $SW_SCAN_CPU_THRESHOLD_PERCENTAGE \* 10`
			cpuTresholdPercentageSleep=`expr 1000 - $cpuTresholdPercentageWork`
			cpuThreshold_tmp1=`expr $SW_SCAN_CPU_THRESHOLD_PERCENTAGE / 10`
			cpuThreshold_tmp2=`expr $cpuThreshold_tmp1 + 1`
			cpuTresholdX=`expr $cpuThreshold_tmp2 \* 10`
			if [ $cpuTresholdX -gt 50 ]; then
				cpuTresholdLoops=50
			else
				cpuTresholdLoops=$cpuTresholdX
			fi
			cpuThreshold=$cpuTresholdLoops:2:$cpuTresholdPercentageWork:$cpuTresholdPercentageSleep
		fi
		
		updateCpuThreshold "${FULL_TOOL_PATH}/config/isotag_config.xml" file "$cpuThreshold"
		updateCpuThreshold "${FULL_TOOL_PATH}/config/slmtag_config.xml" file "$cpuThreshold"
		updateCpuThreshold "${FULL_TOOL_PATH}/config/sw_config.xml" catalog	"$cpuThreshold"
	fi
}

updateCpuThreshold()
{
	# $1 - cit scan config file
	# $2 - config format, either: 'file' or 'catalog'
	# $3 - CPU threshold

	if [ -f "$1" ]; then
		printAndLogTxt "Updating CPU threshold in $1 config file: '$3'"

		if [ "$2" = "file" ]; then
			if [ -z "$3" ]; then
				if [ `cat "$1" | grep "CpuThreshold" | wc -l` -ne 0 ]; then
					# delete the line
					RUN_CMD="cat \"$1\" | sed \"/<CpuThreshold value.*\\/>/d\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
					RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
				fi
			else
				if [ `cat "$1" | grep "CpuThreshold" | grep \"$3\" | wc -l` -eq 0 ]; then
					if [ `cat "$1" | grep "CpuThreshold" | wc -l` -ne 0 ]; then
						# replace the current value
						RUN_CMD="cat \"$1\" | sed \"s/<CpuThreshold value.*\\/>/<CpuThreshold value=\\\"$3\\\"\/>/\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
						RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
					else
						# add CpuThreshold line after <AssumeAutoFS value="remote"/>
						# line break (escaped) is a part of code here
						RUN_CMD="cat \"$1\" | sed \"s/<AssumeAutoFS.*\\/>/<AssumeAutoFS value=\\\"remote\\\"\/>\\\\
<CpuThreshold value=\\\"$3\\\"\/>/\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
						RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
					fi
				fi
			fi
		fi

		if [ "$2" = "catalog" ]; then
			if [ -z "$3" ]; then
				if [ `cat "$1" | grep "cpuThreshold" | wc -l` -ne 0 ]; then
					# delete the line
					RUN_CMD="cat \"$1\" | sed \"/<Attribute name=\\\"cpuThreshold\\\" value.*\\/>/d\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
					RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
				fi
			else
				if [ `cat "$1" | grep "cpuThreshold" | grep \"$3\" | wc -l` -eq 0 ]; then
					if [ `cat "$1" | grep "cpuThreshold" | wc -l` -ne 0 ]; then
						# replace the current value
						RUN_CMD="cat \"$1\" | sed \"s/<Attribute name=\\\"cpuThreshold\\\" value.*\\/>/<Attribute name=\\\"cpuThreshold\\\" value=\\\"$3\\\"\/>/\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
						RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
					else
						# add CpuThreshold line after <Attribute name="assumeAutoFS" value="remote"/>
						# line break (escaped) is a part of code here
						RUN_CMD="cat \"$1\" | sed \"s/<Attribute name=\\\"assumeAutoFS\\\".*\\/>/<Attribute name=\\\"assumeAutoFS\\\" value=\\\"remote\\\"\/>\\\\
<Attribute name=\\\"cpuThreshold\\\" value=\\\"$3\\\"\/>/\" > \"$1.tmp\" "; runLogCMD "${RUN_CMD}"
						RUN_CMD="mv \"$1.tmp\" \"$1\""; runLogCMD "${RUN_CMD}"
					fi
				fi
			fi
		fi
	fi
}

getValueFromYml()
{
	# $1 - yml file
	# $2 - key in the yml file

	if [ -f "$1" ]; then
		# sed 's/^[ ]*//;s/[ ]*$//' trims spaces at both ends
		YML_VAL=`cat "$1" | grep "$2:" | sed "s/$2://" | sed 's/^[ ]*//;s/[ ]*$//'`
	else
		YML_VAL=""
	fi
}

getKeyFromYml()
{
	# $1 - yml file
	# $2 - key in the yml file

	if [ -f "$1" ]; then
		RUN_CMD="cat \"$1\" | grep \"$2:\" | wc -l"; runLogCMD "${RUN_CMD}"

		if [ "$CMD_OUTPUT" -gt 0 ]; then
			YML_KEY=$2
		else
			YML_KEY=""
		fi
	fi
}

updateValueInYml()
{
	# $1 - yml file
	# $2 - key in the yml file
	# $3 - new value

	if [ -f "$1" ]; then
		getKeyFromYml $1 $2
		if [ "$YML_KEY" != "" ]; then
			# update value in yml file, not using -i switch as this switch is not platform independent
			RUN_CMD="cp \"$1\" \"$1.tmp\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="sed \"s/$2:.*/$2: $3/\" \"$1.tmp\" > \"$1\""; runLogCMD "${RUN_CMD}"
			RUN_CMD="rm -f \"$1.tmp\""; runLogCMD "${RUN_CMD}"
		else
			# key missing, add new key/value pair to file
			RUN_CMD="echo \"$2: $3\" >> $1"; runLogCMD "${RUN_CMD}"
		fi
	else
		# file missing, create file and add key/value pair
		RUN_CMD="echo \"$2: $3\" > $1"; runLogCMD "${RUN_CMD}"
	fi
}

generateScannerStatusYml()
{
	printAndLogTxt "Preparing scanner_status.yml file..."
	RUN_CMD="echo \"# Scan statistics\" > $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"

	for NAME in ${STAT_SW_SCAN_LAST_ALL_NAMES}; do
		RUN_CMD="echo \"${NAME}${STAT_LAST_STATUS_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
		RUN_CMD="echo \"${NAME}${STAT_LAST_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
		RUN_CMD="echo \"${NAME}${STAT_LAST_OK_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
		RUN_CMD="echo \"\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	done
	RUN_CMD="echo \"${STAT_HW_SCAN_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_HW_SCAN_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_HW_SCAN_LAST_PREFIX}${STAT_LAST_OK_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_HW_SCAN_CHANGED_TIME}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	
	RUN_CMD="echo \"${STAT_PACK_RESULTS_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_PACK_RESULTS_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_PACK_RESULTS_LAST_PREFIX}${STAT_LAST_OK_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	
	RUN_CMD="echo \"${STAT_UPLOAD_RESULTS_LAST_PREFIX}${STAT_LAST_STATUS_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_UPLOAD_RESULTS_LAST_PREFIX}${STAT_LAST_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"${STAT_UPLOAD_RESULTS_LAST_PREFIX}${STAT_LAST_OK_TIME_SUFFIX}:\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	
	RUN_CMD="echo \"# Helper settings\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		RUN_CMD="echo \"vmman_package_num: 0\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	fi
	RUN_CMD="echo \"sw_scan_for_upload: false\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	RUN_CMD="echo \"hw_scan_for_upload: false\" >> $WORK_DIR/scanner_status.yml"; runLogCMD "${RUN_CMD}"
	
	printAndLogTxt "Preparing scanner_status.yml finished"
}

detectVMMTool()
{
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		# reset values
		VMM_TOOL_INSTALLED=false
		VMM_TOOL_PATH=""

		if [ -f /etc/init.d/vmmansvc ]; then
			# Extract the to the path to vmman.sh file from /etc/init.d/vmmansvc
			# check for VM manager 9.2.24 and later (2 additional checks below for older versions to BE DELETED in the future)
			VMM_TOOL_PATH=`cat /etc/init.d/vmmansvc | $GREP_CMD "^VMMANSVC_TOOL_PATH=" | sed 's/VMMANSVC_TOOL_PATH=//' | sed 's/"//g'`
			if [ -d "${VMM_TOOL_PATH}" ]; then
				printAndLogTxt "VM Manager Tool detected in ${VMM_TOOL_PATH}"
				VMM_TOOL_INSTALLED=true
			else
				# check for VM manager 9.2.23
				VMM_TOOL_PATH=`cat /etc/init.d/vmmansvc | grep "vmman.sh" | grep '\$1' | grep -v runuser | sed 's/\$1//' | xargs dirname 2>/dev/null`
				if [ -d "${VMM_TOOL_PATH}" ]; then
					printAndLogTxt "VM Manager Tool detected in ${VMM_TOOL_PATH}"
					VMM_TOOL_INSTALLED=true
				else
					# check for VM managers 9.2.22 and older
					VMM_TOOL_PATH=`cat /etc/init.d/vmmansvc | grep "vmman.sh" | grep "\-stop" | sed 's/\-stop//' | xargs dirname 2>/dev/null`
					if [ -d "${VMM_TOOL_PATH}" ]; then
						printAndLogTxt "VM Manager Tool detected in ${VMM_TOOL_PATH}"
						VMM_TOOL_INSTALLED=true
					else
						VMM_TOOL_PATH=""
					fi
				fi				
			fi
			if ! $ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION && $VMM_TOOL_INSTALLED && [ "$VMM_TOOL_PATH" = "/var/opt/BESClient/LMT/VMMAN" ]; then
				printAndLogTxt "Detected VM Manager Tool path is inside of the BigFix agent and by default disconnected scanner will not collect data from it. In order to enable data collection from VM Manager Tool installed by BigFix agent set ENABLE_BIGFIX_VM_TOOL_DATA_COLLECTION hidden parameter to true in setup_config.ini file."
				VMM_TOOL_INSTALLED=false
				VMM_TOOL_PATH=""
			fi
		fi
		
		getKeyFromYml "${WORK_DIR}/computer.yml" vmmanagerPresent
		
		if [ "$YML_KEY" != "$VMM_TOOL_INSTALLED" ]; then
			updateValueInYml "${WORK_DIR}/computer.yml" vmmanagerPresent "${VMM_TOOL_INSTALLED}"
		fi
		
		updateValueInYml "${WORK_DIR}/computer.yml" vtechEnabled "${VIRTUALIZATION_HOST_SCAN_ENABLED}"
	fi
}

is_newer()
{
	test_file="$1"
	reference_file="$2"

	output=`[ "$test_file" -nt "$reference_file" ] 2>&1`
	result=$?
	# if there is no output the command ended successfully and the exit code is the boolean result
	# if there is an output, the operator -nt doesn't exist and we have to use find instead of test
	if [ -n "$output" ]; then
		dir_name=`dirname "$test_file"`
		file_name=`basename "$test_file"`
		[ -n "`find "$dir_name" -name "$file_name" -newer "$reference_file"`" ]
		result=$?
	fi
	
	# if result is 0, test_file is newer than reference_file
	return $result
}

checkComputerYmlExists()
{
	if [ ! -f $FULL_TOOL_PATH/work/computer.yml ]; then
		printAndLogTxtExit "The file computer.yml not found. Please, run $FULL_TOOL_PATH/setup.sh script"
	fi
}

checkCITExecutableExists()
{
	CIT_EXEC_NAME=$1
	if [ ! -f $FULL_TOOL_PATH/cit/bin/$CIT_EXEC_NAME ]; then
		logTxt "The file cit/bin/$CIT_EXEC_NAME not found"
		printAndLogTxtExit "CIT scanner is not installed. Please, run $FULL_TOOL_PATH/setup.sh script"
	fi
}

checkPackageUpload()
{
if [ -z "$LMT_SERVER_URL" -a -z "$LMT_SERVER_API_TOKEN" ];
	then
		logTxt "Upload parameters LMT_SERVER_URL and LMT_SERVER_API_TOKEN are not defined."
	else
		if [ -z "$LMT_SERVER_URL" -o -z "$LMT_SERVER_API_TOKEN" ];
			then
				printAndLogTxt "Upload parameters LMT_SERVER_URL and LMT_SERVER_API_TOKEN are not defined. Define the parameters."
				exit 1
			else
				printAndLogTxt "Upload parameters defined. Checking connection to the License Metric Tool server..."
				RUN_CMD="$CURL_PATH $CURL_PARAMETERS --connect-timeout 30 -o /dev/null -w \"%{http_code}\" -H \"Accept:application/json\" -H \"Token:$LMT_SERVER_API_TOKEN\" -H \"Accept-Language: en-US\" -H \"Content-Type:application/octet-stream\" --data-binary \"\" -X POST \"https://$LMT_SERVER_URL/api/sam/v2/scan_results_upload?filename=\""; runLogCMDlogOnly "${RUN_CMD}"
				if [ $EC = "127" ]; 
					then
						printAndLogTxt "Incorrect value of the CURL_PATH parameter or cURL is not installed. Provide a correct value."
						exit 1
				elif [ $EC = "2" ]; 
					then
						printAndLogTxt "Incorrect value of the CURL_PARAMETERS parameter."
						exit 1
				elif [ $EC = "0" -o $EC = "7" -o $EC = "6" ]; 
					then
						if [ "$CMD_OUTPUT" = "400" ]; 
							then	
								printAndLogTxt "Connection successful."
						elif [ "$CMD_OUTPUT" = "401" ];
							then
								printAndLogTxtExit "Incorrect value of the LMT_SERVER_API_TOKEN parameter. Provide a correct value."
								exit 1
						elif [ "$CMD_OUTPUT" = "403" ];
							then
								printAndLogTxtExit "The user does not have the permission to upload packages with disconnected scan results. Add the Manage Uploads permission to the user's role or use the token of a different user."
								exit 1
						elif [ "$CMD_OUTPUT" = "404" -o "$CMD_OUTPUT" = "000" ]; 
							then
								printAndLogTxtExit "Incorrect value of the LMT_SERVER_URL parameter. Provide a correct value."
								exit 1
						else
							printAndLogTxtExit "Error during verification of connection to the License Metric Tool server."
							exit 1
						fi
				else
					printAndLogTxtExit "Error during verification of connection to the License Metric Tool server."
					exit 1
				fi
				
		fi
fi
}
