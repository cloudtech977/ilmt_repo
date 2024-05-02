#!/bin/sh
#################################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2020. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##################################################################################
#

if [ "${FULL_TOOL_PATH}" = "" ]; then
	TOOL_PATH=`dirname "$0"`
	CURR_DIR=`pwd`
	cd "${TOOL_PATH}"
    cd ".."
	FULL_TOOL_PATH=`pwd`
	cd "${CURR_DIR}"
fi 

. "${FULL_TOOL_PATH}"/bin/tools.sh

if [ -d "${FULL_TOOL_PATH}/work/hw_scans_unique" ]; then
	scan_cnt=`ls -t "${FULL_TOOL_PATH}"/work/hw_scans_unique/*.xml | wc -l`
	
	# remove old HW scans if we have unique scans then allowed 
	if [ "$scan_cnt" -gt "$MAX_HW_SCAN_FILES" ]; then
	    current_date=`date +"%s"`
	    if [ "$current_date" = "%s" ]; then
	        os=`uname`
	        if [ "$os" = "SunOS" ]; then
	            current_date=`/usr/bin/truss /usr/bin/date 2>&1 | nawk -F= '/^time()/ {gsub(/ /,"",$2);print $2}'`
	        else
	            current_date=""
	        fi
	    fi
	    check=`echo "$current_date" | grep -c '^[0-9][0-9]*$'`
	    if [ "$check" -eq 1 ]; then
	        # Remove files that are older then $MAX_HW_SCAN_DAYS parameter, 
	        # compare the current system timestamp with the timestamp encoded in
	        # the file name.
	        x=`ls -t "${FULL_TOOL_PATH}"/work/hw_scans_unique/*.xml | awk -F'/' '{ print $NF}' |cut -c23-32 | uniq`
	        for i in $x
	        do
	                diff=`expr '(' $current_date - $i ')'  / 86400`
	                if [ $diff -gt $MAX_HW_SCAN_DAYS ]; then
	                    rm -f "${FULL_TOOL_PATH}"/work/hw_scans_unique/*$i*
	                fi
	        done
	    else
	        # Failed to get current system timestamp, remove old files so we will 
	        # have no more then $MAX_HW_SCAN_FILES HW scans.
	        ls -t "${FULL_TOOL_PATH}"/work/hw_scans_unique/*.xml | awk -F'/' '{ print $NF}' |cut -c8-15 | uniq > "${FULL_TOOL_PATH}"/work/cit_hlm_hw.tmp
	        if [ `cat "${FULL_TOOL_PATH}"/work/cit_hlm_hw.tmp|wc -l` -gt "${MAX_HW_SCAN_FILES}" ]; then
	            xxx=`cat "${FULL_TOOL_PATH}"/work/cit_hlm_hw.tmp | sed -e "1,${MAX_HW_SCAN_FILES}d"`
	            for iii in $xxx
	            do
	                rm -f "${FULL_TOOL_PATH}"/work/hw_scans_unique/*$iii*
	            done
	        fi
	        rm -f "${FULL_TOOL_PATH}"/work/cit_hlm_hw.tmp
	    fi
	fi
fi

