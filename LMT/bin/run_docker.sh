#!/bin/sh

if [ "${FULL_TOOL_PATH}" = "" ]; then
	TOOL_PATH=`dirname "$0"`
	CURR_DIR=`pwd`
	cd "${TOOL_PATH}"
	cd ".."
	FULL_TOOL_PATH=`pwd`
	cd "${CURR_DIR}"
fi 

. "${FULL_TOOL_PATH}"/bin/tools.sh

printAndLogTxt "Starting $DOCKER_SCAN_NAME script ($DISCONNECTED_OS $DISCONNECTED_VERSION)"

# read and set setup_config.ini parameters
setupConfigParameters
prepareDirs

[ ! -d "$DOCKER_DIR" ] && updateOperationStatsAndExit $DS_RC_DOCKER_DIR_NOT_FOUND "$DOCKER_SCAN_NAME" "$STAT_DOCKER_SCAN_LAST_PREFIX" "Invalid $DOCKER_SCAN_NAME data directory: $DOCKER_DIR"

# verify if docker command is available
RUN_CMD="\"${DOCKER_CMD}\" ${DOCKER_OPTS} > /dev/null 2>&1"; runLogCMD "${RUN_CMD}"
[ $EC -ne 0 ] && updateOperationStatsAndExit $DS_RC_DOCKER_CMD_MISSING "$DOCKER_SCAN_NAME" "$STAT_DOCKER_SCAN_LAST_PREFIX" "Docker command (${DOCKER_CMD} ${DOCKER_OPTS}) is not available. Cannot run ${DOCKER_SCAN_NAME}"

# obtain information about the Docker installation
printAndLogTxt "Obtaining information about the Docker installation"
RUN_CMD="\"${DOCKER_CMD}\" ${DOCKER_OPTS} info"; runLogCMDWithOutput "${RUN_CMD}"
[ $EC -ne 0 ] && updateOperationStatsAndExit $DS_RC_DOCKER_CMD_INFO_FAILED "$DOCKER_SCAN_NAME" "$STAT_DOCKER_SCAN_LAST_PREFIX" "Unable to obtain the information."

IMAGES_DIR="$DOCKER_DIR/images"
CONTAINERS_DIR="$DOCKER_DIR/containers"

[ ! -d "${IMAGES_DIR}" ] && runLogCMD "mkdir \"${IMAGES_DIR}\""
[ ! -d "${CONTAINERS_DIR}" ] && runLogCMD "mkdir \"${CONTAINERS_DIR}\""

# save images list
IMAGES_FILE="$DOCKER_DIR/images.lst"
logTxt "Saving images list to ${IMAGES_FILE}"
RUN_CMD="\"${DOCKER_CMD}\" ${DOCKER_OPTS} images | tail -n +2 > \"${IMAGES_FILE}\""; runLogCMD "${RUN_CMD}"

# examine containers
printAndLogTxt "Processing containers"
for CONTAINER in `"${DOCKER_CMD}" ${DOCKER_OPTS} ps | tail -n +2 | awk '{print $1}'`
do
	printAndLogTxt "Processing container ${CONTAINER}"
	if [ ! -d "${CONTAINERS_DIR}/${CONTAINER}" ];
	then
		IMAGE_ID="`"${DOCKER_CMD}" ${DOCKER_OPTS} inspect -f {{.Image}} ${CONTAINER} | cut -f 2 -d :`"
		if [ -z "${IMAGE_ID}" ];
		then
			printAndLogTxt "WARNING: Unable to determine image id for container, skipping..."
			continue
		fi
		SHORT_IMAGE_ID="`echo $IMAGE_ID | cut -c1-12`"
		logTxt "New container found ${CONTAINER} with image id {$SHORT_IMAGE_ID} (${IMAGE_ID})"
		IMAGE1_DIR="${IMAGES_DIR}/${SHORT_IMAGE_ID}"
		if [ ! -d "${IMAGE1_DIR}" ];
		then
			logTxt "Image ${SHORT_IMAGE_ID} data not found, scanning container ${CONTAINER}"
			# have to scan the image
			runLogCMD "mkdir -p \"${IMAGE1_DIR}\""
			"${DOCKER_CMD}" ${DOCKER_OPTS} exec ${CONTAINER} /bin/sh -c "/bin/ls -R / 2>/dev/null"  | \
			while read LINE
			do
				case "$LINE" in
				/*)
					SKIP_DIR=false
					# remove last character, which is a colon ':' from paths listed by ls
					# this command does not work on Solaris 10 sh shell
					# be careful when replacing it with awk or sed for performance reasons
					CURRDIR=${LINE%?}
					# skip host paths mounted on container
					for EXCLUDED_PATH in $DOCKER_EXCLUDED_PATHS
					do
						case "$CURRDIR" in
						*"$EXCLUDED_PATH"/*) 
							SKIP_DIR=true
							logTxt "Excluding directory: $CURRDIR from scanning"
							break 
							;;
						*"$EXCLUDED_PATH") 
							SKIP_DIR=true
							logTxt "Excluding directory: $CURRDIR from scanning"
							break 
							;;
						esac
					done
				esac

				$SKIP_DIR && continue
				
				case "$LINE" in
				*.swtag)
					runLogCMD "mkdir -p \"${IMAGE1_DIR}${CURRDIR}\""
					touch "${IMAGE1_DIR}${CURRDIR}/${LINE}"
					;;
				*.swidtag)
					runLogCMD "mkdir -p \"${IMAGE1_DIR}${CURRDIR}\""
					runLogCMD "\"${DOCKER_CMD}\" ${DOCKER_OPTS} cp ${CONTAINER}:\"${CURRDIR}/${LINE}\" \"${IMAGE1_DIR}${CURRDIR}\""
					;;
				esac
			done
		fi
		# copy the image files to container dir (if any)
		runLogCMD "mkdir \"${CONTAINERS_DIR}/${CONTAINER}\""
		if [ `ls ${IMAGE1_DIR}/* 2>/dev/null | wc -l` -gt 0 ]; then
			logTxt "Copying files from ${IMAGE1_DIR} to ${CONTAINERS_DIR}/${CONTAINER}"
			runLogCMD "cp -R \"${IMAGE1_DIR}\"/* \"${CONTAINERS_DIR}/${CONTAINER}/\""
		fi
	else
		logTxt "Container already scanned, skipping"
	fi
done

# clenup containers
logTxt "Saving containers list to $DOCKER_DIR/containers.lst"
CONTAINERS_LIST="$DOCKER_DIR/containers.lst"
runLogCMD "\"${DOCKER_CMD}\" ${DOCKER_OPTS} ps -q > \"${CONTAINERS_LIST}\""

printAndLogTxt "Cleaning up containers"
for CONTAINER in `/bin/ls "${CONTAINERS_DIR}"`
do
	runLogCMD "grep ${CONTAINER} \"${CONTAINERS_LIST}\" > /dev/null 2>&1"
	if [ $EC -ne 0 ];
	then
		printAndLogTxt "Removing information about container ${CONTAINER}"
		runLogCMD "rm -rf \"${CONTAINERS_DIR}/${CONTAINER}\""
	fi
done

# refresh images list
logTxt "Saving images list to ${IMAGES_FILE}"
runLogCMD "\"${DOCKER_CMD}\" ${DOCKER_OPTS} images | tail -n +2 > \"${IMAGES_FILE}\""

# clean up images
logTxt "Cleaning up images"
for IMAGE in `/bin/ls "${IMAGES_DIR}"`
do
	runLogCMD "grep -w \"${IMAGE}\" \"${IMAGES_FILE}\" > /dev/null 2>&1"
	if [ $EC -ne 0 ];
	then
		logTxt "Removing information about image ${IMAGE}"
		runLogCMD "rm -rf \"${IMAGES_DIR}/${IMAGE}\""
	fi
done

updateOperationStats $DS_RC_OK "$DOCKER_SCAN_NAME" "$STAT_DOCKER_SCAN_LAST_PREFIX"
