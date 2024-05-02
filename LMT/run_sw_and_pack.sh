#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2020. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#################################################################################

TOOL_PATH=`dirname "$0"`
CURR_DIR=`pwd`
cd "${TOOL_PATH}"
if [ `echo "$0" | grep "run_sw_and_pack_CRON.sh" | wc -l` -eq 1 ]; then
    cd ".."
fi
if [ `echo "$0" | grep "run_sw_and_upload_CRON.sh" | wc -l` -eq 1 ]; then
    cd ".."
fi
FULL_TOOL_PATH=`pwd`
cd "${CURR_DIR}"

. "${FULL_TOOL_PATH}/bin/tools.sh"

checkComputerYmlExists
checkCITExecutableExists "wscanfs"

sh "${FULL_TOOL_PATH}"/automation/run_sw.sh
sh "${FULL_TOOL_PATH}"/automation/pack_results.sh
