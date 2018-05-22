#! /bin/ksh
# check_disk_perf: A KSH script for checking filesystem performance
# Author: Anthonie Smit @HotITem BV 2015

# Set test objects
TEST_OBJECT="check_disk_perf.dd"
TEST_LOCATION="/tmp"

# Set target filesystem (this should be your SAN mountpoint)
TEST_FILESYSTEM="/orabackup"

# Set log file location
LOG_FILE_READ="/var/log/check_disk_perf-read.log"
LOG_FILE_WRITE="/var/log/check_disk_perf-write.log"
LOG_FILE_ERROR="/var/log/check_disk_perf-error.log"

# Binaries
BIN_AWK="/usr/bin/awk"
BIN_CP="/usr/bin/cp"
BIN_DATE="/usr/bin/date"
BIN_DD="/usr/bin/dd"
BIN_ECHO="/usr/bin/echo"
BIN_GREP="/usr/bin/egrep"
BIN_RM="/usr/bin/rm"

# Set the time stamp
TIMESTAMP="`${BIN_DATE} +%Y-%m-%d`\t`${BIN_DATE} +%H:%M:%S`"

# Create the test file if it's missing
if ! [ -f "${TEST_LOCATION}/${TEST_OBJECT}" ]; then ${BIN_DD} if=/dev/urandom of="${TEST_LOCATION}/${TEST_OBJECT}" bs=1024 count=102400 2> /dev/null; fi

# Clean up old test files
if [ -f "${TEST_FILESYSTEM}/${TEST_OBJECT}" ]; then ${BIN_RM} "${TEST_FILESYSTEM}/${TEST_OBJECT}"; fi

# Check if target exists
if ! [ -d "${TEST_FILESYSTEM}" ]; then ${BIN_ECHO} "${TIMESTAMP} ERROR: Cannot locate target directory ${TEST_FILESYSTEM}" >> ${LOG_FILE_ERROR}; exit 1; fi

# Copy the test file and save the duration of the copy command
EXEC_TIME=`(time ${BIN_CP} ${TEST_LOCATION}/${TEST_OBJECT} ${TEST_FILESYSTEM}) 2>&1 > /dev/null | ${BIN_GREP} real | ${BIN_AWK} '{print($2)}'`

# Write test data to log file
${BIN_ECHO} "${TIMESTAMP}\t${EXEC_TIME}\t${TEST_FILESYSTEM}" >> ${LOG_FILE_WRITE}

# Read the test file and save the duration of the copy command
EXEC_TIME=`(time ${BIN_CP} ${TEST_FILESYSTEM}/${TEST_OBJECT} /dev/null) 2>&1 > /dev/null | ${BIN_GREP} real | ${BIN_AWK} '{print($2)}'`

# Write test data to log file
${BIN_ECHO} "${TIMESTAMP}\t${EXEC_TIME}\t${TEST_FILESYSTEM}" >> ${LOG_FILE_READ}

# Clean up test file on target filesystem
if [ -f "${TEST_FILESYSTEM}/${TEST_OBJECT}" ]; then /bin/rm "${TEST_FILESYSTEM}/${TEST_OBJECT}"; fi

# Clean up test file on temporary filesystem (this forces a new random file for every run, use this to avoid caching mechanisms)
if [ -f "${TEST_LOCATION}/${TEST_OBJECT}" ]; then /bin/rm "${TEST_LOCATION}/${TEST_OBJECT}"; fi

# Exit script
exit 0
