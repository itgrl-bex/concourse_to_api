#!/bin/bash

##################################################################################
#
# Use this action to push a specific dashboardID, primarily for testing purposes.
# 
# Purpose is to remove action specific logic to files.
# Reason is to simply and shorten main calling script.
# Benefit is that logic for specific action is easy to maintain.
# 
##################################################################################


## Load common functions
source "${baseDir}/lib/common.sh"

source ${baseDir}/lib/libdashboard.sh

_FILENAME="${dashboardID}.json"
getDashboardID $_FILENAME 
# Let's make sure the extracted dashboard ID and the file dashboard ID match.
if [[ "${dashboardID}" == "${dashboard_ID}" ]];
then
  # un-setting option value since the extracted value matches to free memory.
  unset dashboard_ID
else
  logThis "Extracting dashboardID from file ${1} returned value of ${dashboardID} when ${dashboard_ID} was provided." "SEVERE"
fi

# Process Clone tags in name, Dashboard ID, and URL
if [[ "${_FILENAME}" == *"-Clone-"* ]];
then
  logThis "Detected that ${_FILENAME} has documented working copy clone tags." "INFO"
  processCloneFileName $_FILENAME
  # Now that we have changed the filename, we need to process the dashboard name and dashboard ID.
  processCloneID $_FILENAME
else
  if [[ "${dashboardID}" == *"-Clone-"* ]];
  then
    logThis "Detected that the dashboard ID (${dashboardID}) has documented working copy clone tags." "INFO"
    processCloneID $_FILENAME
  else
    echo "Not a clone."
    echo $_FILENAME
    echo $dashboardID
  fi
fi

scrubResponse $responseDir/$_FILENAME

getDashboard $dashboardID
extractResponse $sourceDir/$_FILENAME $sourceDir
scrubResponse $sourceDir/$_FILENAME
if compareFile $responseDir/$_FILENAME $sourceDir/$_FILENAME;
then
  pushDashboard $dashboardID
fi

# Clean up temp files?
if ${CONF_dashboard_clean_tmp_files};
then
  logThis "Cleaning up temp files" "INFO"
  logThis "Cleaning up temp files in ${responseDir} with .response and .response.clone extensions." "DEBUG"
  rm -f ${responseDir}/*.clone
  rm -f ${responseDir}/*.clone.response
  logThis "Cleaning up temp files in ${sourceDir} with .response and .response.clone extensions." "DEBUG"
  rm -f ${sourceDir}/*.clone
  rm -f ${sourceDir}/*.clone.response
else
  logThis "Leaving temp files" "INFO"
fi

setACL "${dashboardID}" "dashboard"

# Validate all dashboards with the tag defined in CONF_dashboard_published_tag have the proper ACL set.
for d in $(searchTag 'dashboard' "${CONF_dashboard_published_tag}");
do
  setACL "${d}" "dashboard"
done