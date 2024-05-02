#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2017. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##################################################################################

. "${FULL_TOOL_PATH}/bin/tools.sh"

BUNDLE_NAME="citbundle.tgz"

# Unpacks citbundle.tgz in the directory provided as the first parameter
unpack_bundle()
{
	BUNDLE_PATH="$1/${BUNDLE_NAME}"
	if [ ! -f "${BUNDLE_PATH}" ]; then
		printAndLogTxtExit "CIT bundle ${BUNDLE_PATH} not found" $DS_RC_INST_CITBUNDLE_NOT_FOUND
	fi

	CDIR=`pwd`
	cd "${1}"
	RUN_CMD="gzip -dc ${BUNDLE_NAME} | tar -xf -"; runLogCMD "${RUN_CMD}"
	cd "${CDIR}"
	if [ $EC -ne 0 ]; then
		printAndLogTxtExit "Unable to extract CIT bundle ${BUNDLE_PATH}" $DS_RC_INST_CITBUNDLE_CANNOT_UPACK
	fi
}

if [ "$DISCONNECTED_OS" = "$DISCONNECTED_OS_AIX" -a "$OS_NAME" != "$OS_NAME_AIX" ]; then
	printAndLogTxtExit "Unsupported Operating System: ${OS_NAME} while expecting $OS_NAME_AIX" $DS_RC_INST_UNSUPPORTED_OS
elif [ "$DISCONNECTED_OS" = "$DISCONNECTED_OS_LINUX" -a "$OS_NAME" != "$OS_NAME_LINUX" ]; then
	printAndLogTxtExit "Unsupported Operating System: ${OS_NAME} while expecting $OS_NAME_LINUX" $DS_RC_INST_UNSUPPORTED_OS
elif [ "$DISCONNECTED_OS" = "$DISCONNECTED_OS_SOLARIS" -a "$OS_NAME" != "$OS_NAME_SOLARIS" ]; then
	printAndLogTxtExit "Unsupported Operating System: ${OS_NAME} while expecting $OS_NAME_SOLARIS" $DS_RC_INST_UNSUPPORTED_OS
fi

UNAME_MACHINE=`uname -m`

if [ "$OS_NAME" = "$OS_NAME_AIX" ]; then
	CIT_PACKAGE_ARCH="aix-ppc64"
elif [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
	if [ "$UNAME_MACHINE" = "x86_64" ]; then
		CIT_PACKAGE_ARCH="linux-x86_64"
	elif [ "`echo ${UNAME_MACHINE} | grep -i "^i[0-9]86$"`" != "" ]; then
		CIT_PACKAGE_ARCH="linux-ix86"
		CIT_BUNDLE_PATH="${FULL_TOOL_PATH}/cit_install/${CIT_PACKAGE_ARCH}"
		unpack_bundle "$CIT_BUNDLE_PATH"
		WCITINST_FULLPATH="${CIT_BUNDLE_PATH}/wcitinst"
		RUN_CMD="${WCITINST_FULLPATH} t"; runLogCMDWithOutput "${RUN_CMD}"
		if [ $EC -ne 0 ]; then
			printAndLogTxt "Falling back to old CIT version, which can be run with libstdc++.so.5."
			CIT_PACKAGE_ARCH="linux-ix86-libstdc5"
		fi
	elif [ `echo ${UNAME_MACHINE} | grep -i "s390x"` ]; then
		CIT_PACKAGE_ARCH="linux-s390x"
	elif [ `echo ${UNAME_MACHINE} | grep -i "ppc64le"` ]; then
		CIT_PACKAGE_ARCH="linux-ppc64le"
	elif [ `echo ${UNAME_MACHINE} | grep -i "ppc64"` ]; then
		CIT_PACKAGE_ARCH="linux-ppc64"
	else
		printAndLogTxtExit "Unsupported $OS_NAME_LINUX Architecture: ${UNAME_MACHINE}" $DS_RC_INST_UNSUPPORTED_ARCH
	fi
elif [ "$OS_NAME" = "$OS_NAME_SOLARIS" ]; then
	UNAME_ALL=`uname -a`
	if [ `echo $UNAME_MACHINE | grep -i sun4 | wc -l` -gt 0 ]; then 
		CIT_PACKAGE_ARCH="solaris"
	elif [ `echo ${UNAME_ALL} | grep -i sparc | wc -l` -gt 0 ]; then
		CIT_PACKAGE_ARCH="solaris"
	else
		CIT_PACKAGE_ARCH="solaris-ix86"
	fi
fi

CIT_BUNDLE_PATH="${FULL_TOOL_PATH}/cit_install/${CIT_PACKAGE_ARCH}"
WCITINST_FULLPATH="${CIT_BUNDLE_PATH}/wcitinst"
# unpack bundle if not extracted already (wcitinst not found)
if [ ! -f "${WCITINST_FULLPATH}" ]; then
	unpack_bundle "${FULL_TOOL_PATH}/cit_install/${CIT_PACKAGE_ARCH}"
fi
RUN_CMD="${WCITINST_FULLPATH} t"; runLogCMDWithOutput "${RUN_CMD}"
if [ $EC -ne 0 ]; then
	if [ "$OS_NAME" = "$OS_NAME_LINUX" ]; then
		printAndLogTxtExit "Cannot run CIT installer. Review the logs directory. Check if libstdc++.so.6 (or libstdc++.so.5 for older Linux versions) is installed." $DS_RC_INST_WCITINST_CANNOT_RUN
	else
		printAndLogTxtExit "Cannot run CIT installer. Review the logs directory." $DS_RC_INST_WCITINST_CANNOT_RUN
	fi
fi

printAndLogTxt "Starting CIT installation (${CIT_PACKAGE_ARCH})..."

CIT_PKG_PREFIX="CIT"
CIT_PKG_EXT="spb"
CIT_SPB_FULLPATH=`ls -1 ${FULL_TOOL_PATH}/cit_install/${CIT_PACKAGE_ARCH}/${CIT_PKG_PREFIX}*.${CIT_PKG_EXT} | head -1`

RUN_CMD="echo $CIT_SPB_FULLPATH | grep $CIT_PKG_PREFIX | grep $CIT_PKG_EXT | wc -l"; runLogCMD "${RUN_CMD}"
if [ "$CMD_OUTPUT" -ne 1 ]; then
	printAndLogTxtExit "File CIT*.spb not found. Make sure CIT bundle package (${BUNDLE_NAME}) exists and rerun the script" $DS_RC_INST_CIT_SPB_CANNOT_FIND
fi

if [ "$CIT_HOME" = "" ]; then
	printAndLogTxtExit "CIT_HOME is not set. Failed to install CIT. Make sure the disconnected scanner package is not corrupted." $DS_RC_INST_CIT_HOME_NOT_SET
else
	# remove CIT directory first as the reinstallation in the directory with existing CIT may fail with error 266 on Solaris (sparc and x86)
	RUN_CMD="rm -rf $CIT_HOME"; runLogCMD "${RUN_CMD}"
	RUN_CMD="mkdir -p $CIT_HOME"; runLogCMD "${RUN_CMD}"
	logTxt "CIT installation directory: $CIT_HOME"
fi

RUN_CMD="${WCITINST_FULLPATH} i LMT-DISCONNECTED -r -s ${CIT_SPB_FULLPATH} -d ${CIT_HOME} -c ${FULL_TOOL_PATH}/logs -p > ${FULL_TOOL_PATH}/logs/wcitinst_log.txt"; runLogCMD "${RUN_CMD}"

if [ $EC -ne 0 ]; then 
	printAndLogTxtExit "CIT installation failed (CIT return code=$EC). Rerun the installation script. If it does not help, gather scanner logs and contact IBM Support" $DS_RC_INST_CIT_INSTALLATION_FAILED; 
fi

RUN_CMD="grep 'PrivMode Action finished with RC: 0' \"${FULL_TOOL_PATH}/logs/wcitinst_log.txt\" | wc -l"; runLogCMD "${RUN_CMD}"

if [ "$CMD_OUTPUT" -eq 1 ]; then 
	printAndLogTxt "CIT installation successful"; 
else 
	printAndLogTxtExit "CIT installation failed" $DS_RC_INST_CIT_INSTALLATION_FAILED; 
fi
