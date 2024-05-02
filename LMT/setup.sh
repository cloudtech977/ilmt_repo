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

. "${FULL_TOOL_PATH}/bin/tools.sh"
ARG=$1

setGrepCmd

RUN_CMD="rm -f ${FULL_TOOL_PATH}/config/successful_setup.info"; runLogCMD "${RUN_CMD}"


# DEFINITION OF FUNCTIONS

# Checks if qclib info is available (runs only on Linux z), if not, which is the case on older Linux z systems
# where qclib API is not available, a user is prompted to provide machine capacity information.
# For automation, to skip prompts for machine capacity information,
# set (export) the following machine capacity variables before running the installation script
# An example for z9 machine with 12 IFL processors running on a shared pool with a capacity of 20, set the variables as follows:
# export TLM_MACHINETYPE=z9
# export TLM_PROCESSORTYPE=IFL
# export TLM_SHAREDPOOLCAPACITY=20
# export TLM_SYSTEMACTIVEPROCESSORS=12
s390xApiCheck()
{
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		if [ `uname -a | grep -i s390 | wc -l` -eq 1 ]; then
			API_SUPPORTED=`${CIT_HOME}/bin/cpuid | grep -E "zVMExtendedInfoAvailable:i=1|KVMVirtualizationAvailable:i=1" | wc -l`
			RUN_CMD="echo ${API_SUPPORTED} > ${FULL_TOOL_PATH}/work/APIsupported"; runLogCMD "${RUN_CMD}"
			if [ ${API_SUPPORTED} -eq 0 ]; then
				if $FAIL_ON_MISSING_CAPACITY_SCAN; then
					printAndLogTxtExit "Cannot obtain capacity information from qclib (check if qc_test returns results)"
				else 
					printAndLogTxt "-- Platform s390/s390x was discovered, and qclib info is not available"
					printAndLogTxt "-- Please input proper parameters and press Enter to accept: "

					while [ "${TLM_MACHINETYPE}" != "z9" -a "${TLM_MACHINETYPE}" != "z10" -a "${TLM_MACHINETYPE}" != "z114" -a "${TLM_MACHINETYPE}" != "z196" -a "${TLM_MACHINETYPE}" != "zEC12" -a "${TLM_MACHINETYPE}" != "zBC12" ]; do
						read -p "-- MachineType (z9, z10, z114, z196, zEC12, zBC12): " TLM_MACHINETYPE
					done

					while [ "${TLM_PROCESSORTYPE}" != "CP" -a "${TLM_PROCESSORTYPE}" != "IFL" ]; do
						read -p "-- ProcessorType (CP, IFL): " TLM_PROCESSORTYPE
					done
		
					TLM_SHAREDPOOLCAPACITY_NO_NUMBERS=`echo $TLM_SHAREDPOOLCAPACITY | sed 's/[[:digit:]]//g'`
					while [ "$TLM_SHAREDPOOLCAPACITY" = "" -o "$TLM_SHAREDPOOLCAPACITY_NO_NUMBERS" != "" ]; do
						read -p "-- SharedPoolCapacity (This is the number of all processors of the CP or IFL type on the physical machine that is running in the shared mode. Specify 0 if LPAR is using only dedicated processors.): " TLM_SHAREDPOOLCAPACITY
						TLM_SHAREDPOOLCAPACITY_NO_NUMBERS=`echo $TLM_SHAREDPOOLCAPACITY | sed 's/[[:digit:]]//g'`
					done

					TLM_SYSTEMACTIVEPROCESSORS_NO_NUMBERS=`echo $TLM_SYSTEMACTIVEPROCESSORS | sed 's/[[:digit:]]//g'`
					while [ "$TLM_SYSTEMACTIVEPROCESSORS" = "" -o "$TLM_SYSTEMACTIVEPROCESSORS_NO_NUMBERS" != "" ]; do
						read -p "-- SystemActiveProcessors (If the Linux on System z image is running on IFL processors, this is the total number of IFL processors in the CEC. If the image is running on CP processors, this is the total number of CP processors in the CEC.): " TLM_SYSTEMACTIVEPROCESSORS
						TLM_SYSTEMACTIVEPROCESSORS_NO_NUMBERS=`echo $TLM_SYSTEMACTIVEPROCESSORS | sed 's/[[:digit:]]//g'`
					done

					RUN_CMD="echo machine_type = ${TLM_MACHINETYPE} > ${FULL_TOOL_PATH}/work/tlmsubcapacity.cfg"; runLogCMD "${RUN_CMD}"
					RUN_CMD="echo processor_type = ${TLM_PROCESSORTYPE} >> ${FULL_TOOL_PATH}/work/tlmsubcapacity.cfg"; runLogCMD "${RUN_CMD}"
					RUN_CMD="echo shared_pool_capacity = ${TLM_SHAREDPOOLCAPACITY} >> ${FULL_TOOL_PATH}/work/tlmsubcapacity.cfg"; runLogCMD "${RUN_CMD}"
					RUN_CMD="echo system_active_processors = ${TLM_SYSTEMACTIVEPROCESSORS} >> ${FULL_TOOL_PATH}/work/tlmsubcapacity.cfg"; runLogCMD "${RUN_CMD}"
				fi
			fi
		fi
	fi
}

# Prompts a user to decide if a system is in a DSD domain or not on Solaris Sparc machines.
# For automation, to skip prompts set (export) the DSD_MODE variable to yes or no, e.g.
# export DSD_MODE=no
# or
# export DSD_MODE=yes
DSDCheck()
{
	if [ "$OS_NAME" = "$OS_NAME_SOLARIS" ]; then
		if [ `uname -a | tr '[A-Z]' '[a-z]' | grep -i sparc | wc -l` -eq 1 ]; then
			
			printAndLogTxt "-- SPARC processor was discovered, this system can be in the DSD domain."
			printAndLogTxt "-- Please answer if the Solaris system is in the DSD domain: "
			
			LOOP_COUNT=3
			while [ ${LOOP_COUNT} -ne 0 ] && [ "${DSD_MODE}" != "yes" ] && [ "${DSD_MODE}" != "y" ] && [ "${DSD_MODE}" != "no" ] && [ "${DSD_MODE}" != "n" ]; do
				printAndLogTxt "-- Is system in the DSD domain (yes/no): "
				read DSD_MODE
				LOOP_COUNT=`expr ${LOOP_COUNT} - 1` 
			done
			
			if [ ${LOOP_COUNT} -eq 0 ] && [ "${DSD_MODE}" != "yes" ] && [ "${DSD_MODE}" != "y" ] && [ "${DSD_MODE}" != "no" ] && [ "${DSD_MODE}" != "n" ]; then
				printAndLogTxt "-- No choice has been made for 3 times, setting default DSD_MODE=no"
				DSD_MODE=no
			fi
			
			case $DSD_MODE in
				yes|y)
					RUN_CMD="touch \"${FULL_TOOL_PATH}/work/dsd_enabled\""; runLogCMD "${RUN_CMD}"
					printAndLogTxt "-- SPARC processor was discovered, this system is in the DSD domain."
					;;
				no|n)
					RUN_CMD="rm -f \"${FULL_TOOL_PATH}/work/dsd_enabled\""; runLogCMD "${RUN_CMD}"
					printAndLogTxt "-- SPARC processor was discovered, this system is not in the DSD domain."
					;;
				*)
					;;
			esac
		fi
	fi
}

printAndLogTxt "Starting configuration of Disconnected Scanner ($DISCONNECTED_OS $DISCONNECTED_VERSION)"

if [ "$ARG" = "-noschedule" ]; then
    printAndLogTxtExit "The noschedule option has been removed in version 9.2.18. For consistency, all disconnected scanner configuration settings are now managed by one master configuration file: setup_config.ini.
To install the scanner and collect the scan data only once (with no scheduling configured), set the HW_SCAN_SCHEDULE_ENABLED parameter to FALSE and make sure that the SW_SCAN_SCHEDULE_ENABLED parameter is set to FALSE (its default value) in the setup.config.ini. Next, run setup.sh without any parameters."
fi

isValidLocale $1 || switchLocale

# read and set setup_config.ini parameters
setupConfigParameters
logConfigParameters

# upgrade config files
upgradeScanConfigFiles

checkInstallDir
printAndLogTxt "Disconnected Scanner will be configured in ${FULL_TOOL_PATH}"
prepareDirs
checkSoftwareCatalog
detectVMMTool

. "${FULL_TOOL_PATH}"/bin/install_scanner.sh

generateScannerStatusYml

printAndLogTxt "Running initial $HW_SCAN_NAME..."
. "$HW_SCAN_FULLPATH"
printAndLogTxt "Initial $HW_SCAN_NAME successful"

generateCronLinks

s390xApiCheck
DSDCheck

SETUP_MODE=true
. "${FULL_TOOL_PATH}/automation/configure.sh"
RC=$?
if [ $RC -ne 0 ]; then 
	printAndLogTxt "Configuration failed" 
	exit $RC
else
	RUN_CMD="echo true > ${FULL_TOOL_PATH}/config/successful_setup.info"; runLogCMD "${RUN_CMD}"
	printAndLogTxt "Script has finished installing and configuring Disconnected Scanner"
fi
