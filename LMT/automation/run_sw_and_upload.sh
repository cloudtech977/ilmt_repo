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

sh "${FULL_TOOL_PATH}/run_sw_and_pack.sh"

sh "${FULL_TOOL_PATH}/upload_results.sh"




