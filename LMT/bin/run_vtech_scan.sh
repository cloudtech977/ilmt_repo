#!/bin/bash
# arguments:
# 1 - outdir_vtech folder - a work folder where all temporary files and going to be created
# 2 - vmman_host_id folder - a where the vtech ID (vmman_host_id) file will be stored 
# 3 - output - a fodler where final output package will be stored/saved
# 4 - true/false information of whether to collect host hostnames or not
# 5 - logPath - a folder in which the run_vtech_scan.log will be created
vtechDir="$1"
vtechIDDir="$2"
outDir="$3"
collectHostnames="$4"
logPath="$5/run_vtech_scan.log"

if [ -f "/etc/init.d/libvirtd" ]; then
	/etc/init.d/libvirtd start
fi

# Set English locale
LANG=C

# allow overwrite a file's content by redirecting some output to it (>)
set +o noclobber

currData=`date -u +"%Y-%m-%d %H:%M:%S UTC"`
logPathTemplate="$vtechDir/run_vtech_scan"
scanfilepath_previous="$vtechDir/vmman_scan_previous.xml" 
scanfilepath_current="$vtechDir/vmman_scan_current.xml"
hostidfilepath="$vtechIDDir/vmman_host_id"

#errors of piped commands are ANDed
set -o pipefail

logMsg() 
{
	TS=`date +%Y-%m-%d:%H:%M:%S`
	echo "$TS $1" >> "$logPath"
}

exitMsg()
{
	logMsg "Exiting."
	echo 2:$1 > "$vtechDir/scan_status.info"
	exit $1
}

exitMsgNoLog()
{
	echo "Exiting."
	echo 2:$1 > "$vtechDir/scan_status.info"
	exit $1
}

exitWithError() 
{ 
	logMsg "Command: '$1', failed with error: $2."	
	exitMsg $2
}

exitWithErrorNoLog() 
{ 
	echo "Command: '$1', failed with error: $2."	
	exitMsg $2
}

exitWrongResult() 
{ 
	logMsg "Command: '$1', returned wrong result: $2."
	exitMsg $3
}

exitIfNotNumber() 
{
	if ! [[ "$2" =~ ^[[:digit:]]+$ ]]; then
		logMsg "A number expected for parameter: $1, while got: $2."
		exitMsg 40
	fi
}

logError() 
{ 
	logMsg "Command: '$1', failed with error: $2. Continuing."
}

setupScanTemplates()
{
	CMD_EXE="mkdir -p "$vtechDir""
	HOST_XML=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithErrorNoLog "$CMD_EXE" $EC; fi
	CMD_EXE="mkdir -p "$outDir""
	HOST_XML=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithErrorNoLog "$CMD_EXE" $EC; fi
	CMD_EXE="mkdir -p "$vtechIDDir""
	HOST_XML=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithErrorNoLog "$CMD_EXE" $EC; fi	
	
	rm -rf "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' > "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "<capacity_report>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <id>__VMMAN_ID__</id>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <virtual_technology>__VTECH_TYPE__</virtual_technology>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <source>STDC</source>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <protocol_version>1</protocol_version>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <report_type>full</report_type>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <timestamp>__SCAN_TS__</timestamp>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <login>N/A</login>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <password></password>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <shared_credentials>false</shared_credentials>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <status>OK</status>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"
	echo "  <url>N/A</url>" >> "$vtechDir/vmman_scan_TEMPLATE_B.xml"

	rm -rf "$vtechDir/vmman_scan_TEMPLATE_E.xml"
	echo "</capacity_report>" > "$vtechDir/vmman_scan_TEMPLATE_E.xml"
	
	rm -rf "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
    if [ "$collectHostnames" = "true" ]; then
		echo "  <host_layer>" > "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <uuid>__HOST_UUID__</uuid>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <name>__HOST_HOSTNAME__</name>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <serial_number>__HOST_SERIAL_NUMBER__</serial_number>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <cores_count>__HOST_TOTAL_CORES__</cores_count>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <active_sockets_count>__HOST_ACTIVE_SOCKETS__</active_sockets_count>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <available_sockets_count>__HOST_AVAILABLE_SOCKETS__</available_sockets_count>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <cpu_model>__HOST_CPU_MODEL__</cpu_model>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <hardware_vendor>__HOST_VENDOR__</hardware_vendor>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <hardware_model>__HOST_HW_MODEL__</hardware_model>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
	else
		echo "  <host_layer>" > "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <uuid>__HOST_UUID__</uuid>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <name>__HOST_SERIAL_NUMBER__</name>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <cores_count>__HOST_TOTAL_CORES__</cores_count>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <active_sockets_count>__HOST_ACTIVE_SOCKETS__</active_sockets_count>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <available_sockets_count>__HOST_AVAILABLE_SOCKETS__</available_sockets_count>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <cpu_model>__HOST_CPU_MODEL__</cpu_model>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <hardware_vendor>__HOST_VENDOR__</hardware_vendor>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"
		echo "    <hardware_model>__HOST_HW_MODEL__</hardware_model>" >> "$vtechDir/vmman_scan_host_TEMPLATE_B.xml"	
    fi	
    
	rm -rf "$vtechDir/vmman_scan_host_TEMPLATE_E.xml"
	echo "  </host_layer> " > "$vtechDir/vmman_scan_host_TEMPLATE_E.xml"

	rm -rf "$vtechDir/vmman_scan_guest_TEMPLATE.xml"
	echo "    <guest_layer>" > "$vtechDir/vmman_scan_guest_TEMPLATE.xml"
	echo "      <uuid>__GUEST_UUID__</uuid>" >> "$vtechDir/vmman_scan_guest_TEMPLATE.xml"
	echo "      <vp_count>__GUEST_VP__</vp_count>" >> "$vtechDir/vmman_scan_guest_TEMPLATE.xml"
	echo "    </guest_layer>" >> "$vtechDir/vmman_scan_guest_TEMPLATE.xml"
    
}

createScanPowerKVM()
{

	CMD_EXE="cat "$vtechDir/vmman_scan_host_TEMPLATE_B.xml""
	HOST_XML=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="cat "$vtechDir/vmman_scan_host_TEMPLATE_E.xml""
	HOST_XML_E=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

	virsh --readonly capabilities | cat > capabilities.xml; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="echo 'cat //host/uuid/text()' | xmllint --shell capabilities.xml | sed '/-------/d' | sed '/^\/ >/d'"
	HOST_UUID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host UUID: '$HOST_UUID'"
	ESCAPED_STRING=$(echo $HOST_UUID | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_UUID__/$ESCAPED_STRING/"`
	rm -f capabilities.xml; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

	CMD_EXE="cat /proc/device-tree/system-id"
	SERIAL_NUMBER=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Serial number: '$SERIAL_NUMBER'"
	ESCAPED_STRING=$(echo $SERIAL_NUMBER | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_SERIAL_NUMBER__/$ESCAPED_STRING/"`

	CMD_EXE="hostname -f"
	HOSTNAME=`eval "$CMD_EXE"`; EC=$?
	if [ $EC -ne 0 ]; then
		CMD_EXE=hostname
		HOSTNAME=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	fi
	logMsg "Hostname: '$HOSTNAME'"
	ESCAPED_STRING=$(echo $HOSTNAME | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_HOSTNAME__/$ESCAPED_STRING/"`

	CMD_EXE="cat /proc/cpuinfo | grep cpu | uniq | gawk -F: '{ print \$2 }' | xargs"
	HOST_CPU_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Cpu model: '$HOST_CPU_MODEL'"
	ESCAPED_STRING=$(echo $HOST_CPU_MODEL | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_CPU_MODEL__/$ESCAPED_STRING/"`

	CMD_EXE="cat /proc/device-tree/vendor"
	HOST_VENDOR=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host vendor: '$HOST_VENDOR'"
	ESCAPED_STRING=$(echo $HOST_VENDOR | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_VENDOR__/$ESCAPED_STRING/"`

	CMD_EXE="cat /proc/device-tree/model"
	HOST_HW_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host hw model: '$HOST_HW_MODEL'"
	ESCAPED_STRING=$(echo $HOST_HW_MODEL | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_HW_MODEL__/$ESCAPED_STRING/"`

	x=`ls -l /proc/device-tree/ | grep xscom@ | rev | cut -d' ' -f 1 | rev`
	rm -f "$vtechDir/tmp.file"
	for i in $x
	do
		hexdump "/proc/device-tree/$i/ibm,hw-module-id" | xargs >> "$vtechDir/tmp.file"
	done
	CMD_EXE="cat "$vtechDir/tmp.file" | sort | uniq | wc -l"
	HOST_ACTIVE_SOCKETS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	exitIfNotNumber "HOST_ACTIVE_SOCKETS" "$HOST_ACTIVE_SOCKETS"
	logMsg "Host sockets count: '$HOST_ACTIVE_SOCKETS'"
	ESCAPED_STRING=$(echo $HOST_ACTIVE_SOCKETS | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_AVAILABLE_SOCKETS__/$ESCAPED_STRING/"`
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_ACTIVE_SOCKETS__/$ESCAPED_STRING/"`
	rm -f "$vtechDir/tmp.file"

	CMD_EXE="ls -l /proc/device-tree/cpus | grep "PowerPC,POWER" | wc -l"
	HOST_TOTAL_CORES=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	exitIfNotNumber "HOST_TOTAL_CORES" "$HOST_TOTAL_CORES"
	logMsg "Host total cores: '$HOST_TOTAL_CORES'"
	ESCAPED_STRING=$(echo $HOST_TOTAL_CORES | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_TOTAL_CORES__/$ESCAPED_STRING/"`

	echo "$HOST_XML" >> "$scanfilepath_current"

	# to check that the virsh command is working
	CMD_EXE="virsh --readonly list --all"
	DOMAIN_ALL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	# allow 1 return code - in case when there will be no running VMs and grep will will not find any results
	CMD_EXE="virsh --readonly list --all | cat | grep running | awk '{print \$1}'"
	DOMAINS_IDS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ] && [ $EC -ne 1 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="mktemp"
	TMP_FILE=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	echo "$DOMAINS_IDS" | while read DOM; do

		# shut off VMs don't have numbers, but "-", so skip them
		if [[ "$DOM" != *[[:digit:]]* ]]; then
			continue
		fi
	
		CMD_EXE="cat "$vtechDir/vmman_scan_guest_TEMPLATE.xml""
		DOM_XML_TEMPL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

		CMD_EXE="virsh --readonly domuuid $DOM 2>/dev/null | cat"
		DOM_UUID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		
		CMD_EXE="virsh dumpxml $DOM | cat > $TMP_FILE"
		eval "$CMD_EXE"; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		CMD_EXE="virsh domxml-to-native qemu-argv --xml $TMP_FILE"
		output=`eval "$CMD_EXE"`; EC=$?
		
		unset DOM_SOCKETS
		unset DOM_CORES
		
		if [ $EC -eq 0 ]; then
			if [[ "$output" =~ .*sockets=([[:digit:]]+).* ]]; then
				DOM_SOCKETS=${BASH_REMATCH[1]}
				if [[ "$output" =~ .*cores=([[:digit:]]+).* ]]; then
					DOM_CORES=${BASH_REMATCH[1]}
				fi
			fi
		fi
		
		if [ $EC -ne 0 ] || ! [[ "$DOM_SOCKETS" =~ ^[[:digit:]]+$ ]] || ! [[ "$DOM_CORES" =~ ^[[:digit:]]+$ ]]; then
			TOPOLOGY=`cat $TMP_FILE | grep '<topology '`
			unset DOM_SOCKETS
			unset DOM_CORES
			if [[ "$TOPOLOGY" =~ .*sockets=\'([[:digit:]]+)\'.* ]]; then
				DOM_SOCKETS=${BASH_REMATCH[1]}
				if [[ "$TOPOLOGY" =~ .*cores=\'([[:digit:]]+)\'.* ]]; then
					DOM_CORES=${BASH_REMATCH[1]}
				fi
			fi
		fi
		
		exitIfNotNumber "GUEST_SOCKETS" "$DOM_SOCKETS"
		exitIfNotNumber "GUEST_CORES" "$DOM_CORES"
		
		DOM_VP=$(($DOM_SOCKETS * $DOM_CORES))
		
		logMsg "VM info: '$DOM', '$DOM_UUID', '$DOM_VP'"

		ESCAPED_STRING=$(echo $DOM_UUID | sed -e 's/[\/&]/\\&/g')
		DOM_XML=`echo "$DOM_XML_TEMPL" | sed "s/__GUEST_UUID__/$ESCAPED_STRING/"`
		ESCAPED_STRING=$(echo $DOM_VP | sed -e 's/[\/&]/\\&/g')
		DOM_XML=`echo "$DOM_XML" | sed "s/__GUEST_VP__/$ESCAPED_STRING/"`
	
		echo "$DOM_XML" >> "$scanfilepath_current"
	done
	rm -f $TMP_FILE

	echo "$HOST_XML_E" >> "$scanfilepath_current"

}

createScanKVM()
{

	CMD_EXE="cat "$vtechDir/vmman_scan_host_TEMPLATE_B.xml""
	HOST_XML=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="cat "$vtechDir/vmman_scan_host_TEMPLATE_E.xml""
	HOST_XML_E=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

	virsh --readonly capabilities | cat > capabilities.xml; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="echo 'cat //host/uuid/text()' | xmllint --shell capabilities.xml | sed '/-------/d' | sed '/^\/ >/d'"
	HOST_UUID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host UUID: '$HOST_UUID'"
	ESCAPED_STRING=$(echo $HOST_UUID | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_UUID__/$ESCAPED_STRING/"`
	rm -f capabilities.xml; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

	CMD_EXE="dmidecode -s system-serial-number | sed '/^#/d' | head -1"
	SERIAL_NUMBER=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Serial number: '$SERIAL_NUMBER'"
	ESCAPED_STRING=$(echo $SERIAL_NUMBER | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_SERIAL_NUMBER__/$ESCAPED_STRING/"`

	CMD_EXE="hostname -f"
	HOSTNAME=`eval "$CMD_EXE"`; EC=$?
	if [ $EC -ne 0 ]; then
		CMD_EXE=hostname
		HOSTNAME=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	fi
	logMsg "Hostname: '$HOSTNAME'"
	ESCAPED_STRING=$(echo $HOSTNAME | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_HOSTNAME__/$ESCAPED_STRING/"`

	CMD_EXE="dmidecode -s system-manufacturer | sed '/^#/d' | head -1"
	HOST_VENDOR=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host vendor: '$HOST_VENDOR'"
	ESCAPED_STRING=$(echo $HOST_VENDOR | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_VENDOR__/$ESCAPED_STRING/"`

	CMD_EXE="dmidecode -s system-product-name | sed '/^#/d' | head -1"
	HOST_HW_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host hw model: '$HOST_HW_MODEL'"
	ESCAPED_STRING=$(echo $HOST_HW_MODEL | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_HW_MODEL__/$ESCAPED_STRING/"`

	CMD_EXE="dmidecode | grep \"Core Count:\" | wc -l"
	HOST_ACTIVE_SOCKETS=`eval "$CMD_EXE"`; EC=$?
	
	if [ $EC -eq 0 ]; then
		logMsg "Host sockets count: '$HOST_ACTIVE_SOCKETS'"

		CMD_EXE="dmidecode | grep \"Core Count:\" | awk '{print \$3}' | awk '{x+=\$0}END{print x}'"
		HOST_TOTAL_CORES=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		exitIfNotNumber "HOST_TOTAL_CORES" "$HOST_TOTAL_CORES"
		logMsg "Host total cores: '$HOST_TOTAL_CORES'"
	
		#"dmidecode -s processor-version" lists all processors, if a socket is not active(empty) it will list "Not Specified"
		CMD_EXE="dmidecode -s processor-version | sed '/^#/d' | sed '/Not Specified/d' | head -1"
		HOST_CPU_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		logMsg "Cpu model: '$HOST_CPU_MODEL'"
	else
		CMD_EXE="dmidecode | grep -n -i \"Central Processor\" | wc -l"
		HOST_ACTIVE_SOCKETS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		exitIfNotNumber "HOST_ACTIVE_SOCKETS" "$HOST_ACTIVE_SOCKETS"
		logMsg "Host sockets count: '$HOST_ACTIVE_SOCKETS'"
		
		CMD_EXE="cat /proc/cpuinfo  | grep processor | wc -l"
		HOST_TOTAL_CORES=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		exitIfNotNumber "HOST_TOTAL_CORES" "$HOST_TOTAL_CORES"
		logMsg "Host total cores: '$HOST_TOTAL_CORES'"
		
		CMD_EXE="cat /proc/cpuinfo | grep \"model name\" | awk -F': ' '{ print \$2 }' | head -1"
		HOST_CPU_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		logMsg "Cpu model: '$HOST_CPU_MODEL'"
	fi
	
	ESCAPED_STRING=$(echo $HOST_ACTIVE_SOCKETS | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_AVAILABLE_SOCKETS__/$ESCAPED_STRING/"`
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_ACTIVE_SOCKETS__/$ESCAPED_STRING/"`
	
	ESCAPED_STRING=$(echo $HOST_TOTAL_CORES | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_TOTAL_CORES__/$ESCAPED_STRING/"`
	
	ESCAPED_STRING=$(echo $HOST_CPU_MODEL | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_CPU_MODEL__/$ESCAPED_STRING/"`

	echo "$HOST_XML" >> "$scanfilepath_current"

	# to check that the virsh command is working
	CMD_EXE="virsh --readonly list --all"
	DOMAIN_ALL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	# allow 1 return code - in case when there will be no running VMs and grep will will not find any results
	CMD_EXE="virsh --readonly list --all | cat | grep running | awk '{print \$1}'"
	DOMAINS_IDS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ] && [ $EC -ne 1 ]; then exitWithError "$CMD_EXE" $EC; fi
	echo "$DOMAINS_IDS" | while read DOM; do

		# shut off VMs don't have numbers, but "-", so skip them
		if [[ "$DOM" != *[[:digit:]]* ]]; then
			continue
		fi
	
		CMD_EXE="cat "$vtechDir/vmman_scan_guest_TEMPLATE.xml""
		DOM_XML_TEMPL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

		CMD_EXE="virsh --readonly domuuid $DOM 2>/dev/null | cat"
		DOM_UUID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

		CMD_EXE="virsh --readonly vcpucount $DOM --current --live 2>/dev/null | cat"
		DOM_VP=`eval "$CMD_EXE"`; # don't catch errors ('domain is transient' issue)
		if ! [[ "$DOM_VP" =~ ^[[:digit:]]+$ ]]; then
			# support for virsh version <0.9.4 (0.8.2)
			CMD_EXE="virsh --readonly vcpuinfo $DOM 2>/dev/null | cat | grep '^VCPU' | wc -l"
			DOM_VP=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		fi		
		exitIfNotNumber "GUEST_VP" "$DOM_VP"
		logMsg "VM info: '$DOM', '$DOM_UUID', '$DOM_VP'"

		ESCAPED_STRING=$(echo $DOM_UUID | sed -e 's/[\/&]/\\&/g')
		DOM_XML=`echo "$DOM_XML_TEMPL" | sed "s/__GUEST_UUID__/$ESCAPED_STRING/"`
		ESCAPED_STRING=$(echo $DOM_VP | sed -e 's/[\/&]/\\&/g')
		DOM_XML=`echo "$DOM_XML" | sed "s/__GUEST_VP__/$ESCAPED_STRING/"`
	
		echo "$DOM_XML" >> "$scanfilepath_current"
	done

	echo "$HOST_XML_E" >> "$scanfilepath_current"

}

createScanXEN()
{

	CMD_EXE="cat "$vtechDir/vmman_scan_host_TEMPLATE_B.xml""
	HOST_XML=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="cat "$vtechDir/vmman_scan_host_TEMPLATE_E.xml""
	HOST_XML_E=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

	CMD_EXE="xe host-list hostname=`hostname` params=uuid | grep -i uuid | awk -F': ' '{ print \$2 }' | head -1"
	HOST_UUID=`eval "$CMD_EXE"`; EC=$?
	if [ $EC -ne 0 ]; then
		CMD_EXE="dmidecode -s system-uuid | sed '/^#/d' | head -1"
		HOST_UUID=`eval "$CMD_EXE"`; EC=$?
		# check if the command result is a UUID - dmidecode sometimes returns "Not Settable"
		UUID_FORMAT='[0-9A-Fa-f]{8}(-([0-9a-fA-F]){4}){3}-[0-9A-Fa-f]{12}'
		if [ $EC -ne 0 ] || (! [[ $HOST_UUID =~ ^$UUID_FORMAT$ ]]); then
			CMD_EXE="xl list -v 0 | awk 'NR>1'"
			HOST=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
			HOST_UUID=`[[ $HOST =~ .+($UUID_FORMAT) ]] && echo ${BASH_REMATCH[1]}`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
			# check if the UUID is valid - xl sometimes returns UUID consisting of '0' and '-' characters
			NONZERO_UUID='.*[1-9A-Fa-f].*'
			if (! [[ $HOST_UUID =~ ^$UUID_FORMAT$ ]]) || (! [[ $HOST_UUID =~ $NONZERO_UUID ]]); then
				logMsg "Incorrect host UUID: $HOST_UUID."
				exitMsg 50
			fi
		fi
	fi
	
	logMsg "Host UUID: '$HOST_UUID'"
	ESCAPED_STRING=$(echo $HOST_UUID | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_UUID__/$ESCAPED_STRING/"`
	
	CMD_EXE="dmidecode -s system-serial-number | sed '/^#/d' | head -1"
	SERIAL_NUMBER=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Serial number: '$SERIAL_NUMBER'"
	ESCAPED_STRING=$(echo $SERIAL_NUMBER | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_SERIAL_NUMBER__/$ESCAPED_STRING/"`
	
	CMD_EXE="hostname -f"
	HOSTNAME=`eval "$CMD_EXE"`; EC=$?
	if [ $EC -ne 0 ]; then
		CMD_EXE=hostname
		HOSTNAME=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	fi
	logMsg "Hostname: '$HOSTNAME'"
	ESCAPED_STRING=$(echo $HOSTNAME | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_HOSTNAME__/$ESCAPED_STRING/"`
	
	CMD_EXE="dmidecode -s system-manufacturer | sed '/^#/d' | head -1"
	HOST_VENDOR=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host vendor: '$HOST_VENDOR'"
	ESCAPED_STRING=$(echo $HOST_VENDOR | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_VENDOR__/$ESCAPED_STRING/"`
		
	CMD_EXE="dmidecode -s system-product-name | sed '/^#/d' | head -1"
	HOST_HW_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Host hw model: '$HOST_HW_MODEL'"
	ESCAPED_STRING=$(echo $HOST_HW_MODEL | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_HW_MODEL__/$ESCAPED_STRING/"`
	
	CMD_EXE="dmidecode | grep \"Core Count:\" | wc -l"
	HOST_ACTIVE_SOCKETS=`eval "$CMD_EXE"`; EC=$?
	
	if [ $EC -eq 0 ]; then
		logMsg "Host sockets count: '$HOST_ACTIVE_SOCKETS'"

		CMD_EXE="dmidecode | grep \"Core Count:\" | awk '{ print \$3 }' | awk '{x+=\$0}END{print x}'"
		HOST_TOTAL_CORES=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		exitIfNotNumber "HOST_TOTAL_CORES" "$HOST_TOTAL_CORES"
		logMsg "Host total cores: '$HOST_TOTAL_CORES'"

		CMD_EXE="dmidecode -s processor-version | sed '/^#/d' | sed '/Not Specified/d' | head -1"
		HOST_CPU_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		logMsg "Cpu model: '$HOST_CPU_MODEL'"
	else
		CMD_EXE="dmidecode | grep -n -i \"Central Processor\" | wc -l"
		HOST_ACTIVE_SOCKETS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		exitIfNotNumber "HOST_ACTIVE_SOCKETS" "$HOST_ACTIVE_SOCKETS"
		logMsg "Host sockets count: '$HOST_ACTIVE_SOCKETS'"
		
		CMD_EXE="cat /proc/cpuinfo  | grep processor | wc -l"
		HOST_TOTAL_CORES=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		exitIfNotNumber "HOST_TOTAL_CORES" "$HOST_TOTAL_CORES"
		logMsg "Host total cores: '$HOST_TOTAL_CORES'"
		
		CMD_EXE="cat /proc/cpuinfo | grep \"model name\" | awk -F': ' '{ print \$2 }' | head -1"
		HOST_CPU_MODEL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		logMsg "Cpu model: '$HOST_CPU_MODEL'"
	fi
	
	ESCAPED_STRING=$(echo $HOST_ACTIVE_SOCKETS | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_AVAILABLE_SOCKETS__/$ESCAPED_STRING/"`
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_ACTIVE_SOCKETS__/$ESCAPED_STRING/"`
		
	ESCAPED_STRING=$(echo $HOST_TOTAL_CORES | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_TOTAL_CORES__/$ESCAPED_STRING/"`
	
	ESCAPED_STRING=$(echo $HOST_CPU_MODEL | sed -e 's/[\/&]/\\&/g')
	HOST_XML=`echo "$HOST_XML" | sed "s/__HOST_CPU_MODEL__/$ESCAPED_STRING/"`

	echo "$HOST_XML" >> "$scanfilepath_current"
	
	CMD_EXE="xl vm-list | awk 'NR>1'"
	DOMAINS=`eval "$CMD_EXE"`; EC=$?
	if [ $EC -ne 0 ]; then
		CMD_EXE="xl list-vm | awk 'NR>1'"
		DOMAINS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	fi

	if [ ! -z "$DOMAINS" ]; then
		echo "$DOMAINS" | while read DOM; do
	
			CMD_EXE="cat "$vtechDir/vmman_scan_guest_TEMPLATE.xml""
			DOM_XML_TEMPL=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

			CMD_EXE="echo \"$DOM\" | awk '{ print \$1 }'"
			DOM_UUID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		
			CMD_EXE="echo \"$DOM\" | awk '{ print \$2 }'"
			DOM_ID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

			CMD_EXE="xl vcpu-list $DOM_ID | awk 'NR>1' | awk '{ print \$4 }' | grep -v - | wc -l"
			DOM_VP=`eval "$CMD_EXE"`; EC=$?; if [ $EC -gt 1 ]; then exitWithError "$CMD_EXE" $EC; fi

			exitIfNotNumber "GUEST_VP" "$DOM_VP"
			logMsg "VM info: '$DOM_UUID', '$DOM_VP'"

			ESCAPED_STRING=$(echo $DOM_UUID | sed -e 's/[\/&]/\\&/g')
			DOM_XML=`echo "$DOM_XML_TEMPL" | sed "s/__GUEST_UUID__/$ESCAPED_STRING/"`
		
			ESCAPED_STRING=$(echo $DOM_VP | sed -e 's/[\/&]/\\&/g')
			DOM_XML=`echo "$DOM_XML" | sed "s/__GUEST_VP__/$ESCAPED_STRING/"`
	
			echo "$DOM_XML" >> "$scanfilepath_current"
		done
	fi

	echo "$HOST_XML_E" >> "$scanfilepath_current"

}

# prepare template files and create folder
setupScanTemplates

if [ -f "$logPath" ] ; then
	# 1MB size
	MAXSIZE=1000000
	SIZE=$(wc -c "$logPath" | cut -f 1 -d ' ')
	if [ $SIZE -ge $MAXSIZE ]; then
		mv -f "$logPath" "$logPathTemplate_2.log"
		touch "$logPath"
	fi
else
	touch "$logPath"
fi


logMsg "Starting."

echo $currData > "$vtechDir/last_scan_attempt.info"
echo 0 > "$vtechDir/scan_status.info"

# determine a virtualization type:
VIRT_TYPE="Unknown"

# test for libvirt (KVM x86 or power)
CMD_EXE="virsh --readonly capabilities 2>/dev/null | cat | grep \"domain type\" | grep -i kvm | wc -l"
VIRT_TEST=`eval "$CMD_EXE"`;
EC=$?
if [ $EC -ne 0 ]; then
	#test for Xen
	CMD_EXE2="virsh --readonly capabilities 2>/dev/null | cat | grep \"domain type\" | grep -i xen | wc -l"
	VIRT_TEST2=`eval "$CMD_EXE2"`;
	EC2=$?
	if [ $EC2 -ne 0 ]; then
		CMD_EXE3="xl list 2>/dev/null | cat | wc -l"
		VIRT_TEST3=`eval "$CMD_EXE3"`;
		EC3=$?
		if [ $EC3 -ne 0 ]; then
			logMsg 'Supported virtualization not found'
			logMsg "Command: '$CMD_EXE' exited with $EC with output: '$VIRT_TEST'"
			logMsg "Command: '$CMD_EXE2' exited with $EC2 with output: '$VIRT_TEST2'"
			logMsg "Command: '$CMD_EXE3' exited with $EC3 with output: '$VIRT_TEST3'"
			exitMsg 20
		fi
	fi
	
	if ([ $EC2 -eq 0 ] && [ $VIRT_TEST2 -gt 0 ]) || ([ $EC3 -eq 0 ] && [ $VIRT_TEST3 -gt 0 ]); then
		logMsg 'Xen virtualization detected'
		VIRT_TYPE="XEN"
	else
		if [ $EC2 -eq 0 ]; then
			exitWrongResult "$CMD_EXE2" "$VIRT_TEST2" 20;
		else
			exitWrongResult "$CMD_EXE3" "$VIRT_TEST3" 20;
		fi
	fi
else
	if [ $VIRT_TEST -gt 0 ]; then
		logMsg 'KVM virtualization detected'
		CMD_EXE2="uname -i | grep ppc | wc -l"
		VIRT_TEST2=`eval "$CMD_EXE2"`;
		EC2=$?
		if [ $EC2 -eq 0 ] && [ $VIRT_TEST2 -gt 0 ]; then
			logMsg 'KVM type is Power'
			VIRT_TYPE="KVM_PPC"
		else
			CMD_EXE3="uname -i | grep 86 | wc -l"
			VIRT_TEST3=`eval "$CMD_EXE3"`;
			EC3=$?
			if [ $EC3 -eq 0 ] && [ $VIRT_TEST3 -gt 0 ]; then
				logMsg 'KVM type is x86'
				VIRT_TYPE="KVM_X86"
			else
				logMsg 'Failed to determine KVM virtualization architecture'
				logMsg "Command: '$CMD_EXE2' exited with $EC2 with output: '$VIRT_TEST2'"
				logMsg "Command: '$CMD_EXE3' exited with $EC3 with output: '$VIRT_TEST3'"
				exitMsg 30
			fi
		fi
	else
		exitWrongResult "$CMD_EXE" "$VIRT_TEST" 20;
	fi
fi


CMD_EXE="cat "$vtechDir/vmman_scan_TEMPLATE_B.xml""
REPORT_XML_TEMPL_B=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
CMD_EXE="cat "$vtechDir/vmman_scan_TEMPLATE_E.xml""
REPORT_XML_TEMPL_E=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi

if [ -f "$hostidfilepath" ]; then
	CMD_EXE="cat "$hostidfilepath""
	VMMAN_ID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
fi

if [[ "$VMMAN_ID" =~ ^[[:digit:]]+$ ]]; then
	CMD_EXE="echo $VMMAN_ID | head -c19"
	VMMAN_ID=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	logMsg "Current VMMAN_ID: '$VMMAN_ID'"
else
	CMD_EXE="date +%s | head -c10"
	VMMAN_ID1=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	CMD_EXE="hostname"
	hostname > "$vtechDir/host_system.ids"; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	if [ -f "/sbin/ifconfig" ]; then
		CMD_EXE="ifconfig 1"
		/sbin/ifconfig | awk '/inet / && $2 != "127.0.0.1" && $2 != "addr:127.0.0.1" { print $2 }' | sed "s/addr://" >> "$vtechDir/host_system.ids"; EC=$?; if [ $EC -ne 0 ]; then logError "$CMD_EXE" $EC; fi
		CMD_EXE="ifconfig 2"
		/sbin/ifconfig | awk '/ether / { print $2 }' | sort -u >> "$vtechDir/host_system.ids"; EC=$?; if [ $EC -ne 0 ]; then logError "$CMD_EXE" $EC; fi
		CMD_EXE="ifconfig 3"
		/sbin/ifconfig | awk '/HWaddr / { print $5 }' | sort -u >> "$vtechDir/host_system.ids"; EC=$?; if [ $EC -ne 0 ]; then logError "$CMD_EXE" $EC; fi
	fi
	CMD_EXE="cksum "$vtechDir/host_system.ids" | awk '{ print \$1}' | head -c9"
	VMMAN_ID2=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
	rm -f "$vtechDir/host_system.ids"
	VMMAN_ID=$VMMAN_ID1$VMMAN_ID2
	echo $VMMAN_ID > "$hostidfilepath"
	logMsg "New VMMAN_ID: '$VMMAN_ID'"
fi

exitIfNotNumber "VMMAN_ID" "$VMMAN_ID"
REPORT_XML=`echo "$REPORT_XML_TEMPL_B" | sed "s/__VMMAN_ID__/$VMMAN_ID/"`

CMD_EXE="date -u +%Y-%m-%dT%H:%M:%S.000Z"
SCAN_TS=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
CMD_EXE="date -u +%s"
SCAN_EPOCH=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
logMsg "Scan TS: '$SCAN_TS'"
REPORT_XML=`echo "$REPORT_XML" | sed "s/__SCAN_TS__/$SCAN_TS/"`

REPORT_XML=`echo "$REPORT_XML" | sed "s/__VTECH_TYPE__/$VIRT_TYPE/"`

rm -rf "$scanfilepath_current"
echo "$REPORT_XML" > "$scanfilepath_current"

echo $VIRT_TYPE > "$vtechDir/virt_tech.info"

if [ "$VIRT_TYPE" == "XEN" ]; then
	createScanXEN
else	
	if [ "$VIRT_TYPE" == "KVM_PPC" ]; then
		createScanPowerKVM
	else
		createScanKVM
	fi	
fi


echo "$REPORT_XML_TEMPL_E" >> "$scanfilepath_current"

previousNeedUpdate=1

if [ -f "$scanfilepath_previous" ]; then

	CMD_EXE="diff -I '<timestamp>' "$scanfilepath_current" "$scanfilepath_previous" "
	DIFF_OUT=`eval "$CMD_EXE"`;

	if [ $? -ne 0 ]; then
		CMD_EXE="cp 1"
		cp -f "$scanfilepath_current" "$outDir/vmman_scan_"$VMMAN_ID"_"$SCAN_EPOCH".xml"; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		logMsg 'Scan is different. Scan saved to "$outDir/vmman_scan_'$VMMAN_ID'_'$SCAN_EPOCH'.xml"'
		logMsg "Scan diff: $DIFF_OUT"
	else
		CMD_EXE="expr `date +%s -r "$scanfilepath_current"` - `date +%s -r "$scanfilepath_previous"`"
		TIME_DIFF=`eval "$CMD_EXE"`; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
		if [ $TIME_DIFF -gt 43200 ]; then
			CMD_EXE="cp 1"
			cp -f "$scanfilepath_current" "$outDir/vmman_scan_"$VMMAN_ID"_"$SCAN_EPOCH".xml"; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
			logMsg 'No scan difference, but it is more then 12h from the last saved scan results. Scan saved to "$outDir/vmman_scan_'$VMMAN_ID'_'$SCAN_EPOCH'.xml"'
			logMsg "Scan time diff: $TIME_DIFF"
		else
			logMsg 'No scan difference. Skipping scan.'
			previousNeedUpdate=0
		fi
	fi
else
	logMsg 'No previous scan. Scan saved to "'$outDir'/vmman_scan_'$VMMAN_ID'_'$SCAN_EPOCH'.xml"'
	CMD_EXE="cp 2"
	cp -f "$scanfilepath_current" "$outDir/vmman_scan_"$VMMAN_ID"_"$SCAN_EPOCH".xml"; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
fi

if [ $previousNeedUpdate -ne 0 ]; then
	CMD_EXE="cp 4"
	cp -f "$scanfilepath_current" "$scanfilepath_previous"; EC=$?; if [ $EC -ne 0 ]; then exitWithError "$CMD_EXE" $EC; fi
fi

logMsg "Finished."
logMsg " "

echo 1 > "$vtechDir/scan_status.info"
echo $currData > "$vtechDir/last_scan_success.info"

exit 0
