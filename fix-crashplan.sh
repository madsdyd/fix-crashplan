#!/bin/bash

# Enable echo of all commands.
#set -x 

# Make sure we do not fail for a lot of common errors.
set -euo pipefail

# Common helper functions. Note the usage of SCRIPTNAME as an output variable.
# Lets color a bit. This is clearly a waste of time... (setup in load function).
SCRIPTNAME=fix-crashplan
OUTPUTCOLOR=
NOCOLOR=
function die() {
    echo "${OUTPUTCOLOR}[${SCRIPTNAME}]${NOCOLOR} $(date +%T) ERROR:" "$@"
    # echo "$(date +%T.%N) ERROR:" "$@" >> ${LOG_FILE}
    exit 1
}

function info() {
    echo "${OUTPUTCOLOR}[${SCRIPTNAME}]${NOCOLOR} $(date +%T) INFO:" "$@"
    # echo "$(date +%T.%N) INFO:" "$@" >> ${LOG_FILE}
}

function warn() {
    echo "${OUTPUTCOLOR}[${SCRIPTNAME}]${NOCOLOR} $(date +%T) WARN:" "$@"

    # echo "$(date +%T.%N) WARN:" "$@" >> ${LOG_FILE}
}

# Setup some stuff.

# Set some variables on load - most "important": If tty output, lets put some colors on.
function onLoad() {
  if [ -t 1 ] ; then
    OUTPUTCOLOR=$(tput setaf 2)  # Green
    NOCOLOR=$(tput sgr0)
  fi
}
onLoad

# ACTUAL CODE BEGINS HERE

# CrashPlan installation folder
# We try to get install folder with the code42 binary actual folder
# Using which -a  for bash, or where in csh/zsh
CRASHPLAN_INSTALL_DIR=`realpath $(which -a code42) | sed 's!/bin.*$!!'`
echo "Using CRASHPLAN_INSTALL_DIR=${CRASHPLAN_INSTALL_DIR}"

# If not detected, uncomment and modify the line below
#CRASHPLAN_INSTALL_DIR=/usr/local/crashplan

CRASHPLAN_NATIVE_LIBS_SOURCE=ubuntu20

######################################################################
function usage() {
    echo "Usage: $0 [<crashplan-install-file>]"
    echo
    echo "If no install file is given, it will try to get it from update folder of your installation."
    echo "The installation folder will be guessed, if it fails, please modify in the script."
    echo
    echo "Example: $0 /tmp/CrashPlanSmb_10.2.1_15252000061021_16_Linux.tgz"
    echo
    echo "You can get the install file from here: https://console.us2.crashplanpro.com/app/#/console/app-downloads"
    echo "Note, that it requires login."
    echo
    exit;
}

# Check that we have needed executables
which gzip &> /dev/null || die "Unable to find gzip on path. Please install this program"
which tar &> /dev/null || die "Unable to find tar on path. Please install this program"
which cpio &> /dev/null || die "Unable to find cpio on path. Please install this program"
which sed  &> /dev/null || die "Unable to find sed on path. Please install this program"

# Setup the variable that holds the crashplan install file
set +u
CRASHPLAN_INSTALL_FILE=$1
set -u


function copyFromCpioFile() {
    CPIO_FILE=$1
    DEST_DIR=$2
    test -f "${CPIO_FILE}" || die "Unable to find cpio file at ${CPIO_FILE}"
    test -d "${DEST_DIR}" || die "Unable to find destination folder at ${DEST_DIR}"

    # Extract nlib folder
    (cd "${DEST_DIR}" && (gzip -cd "${CPIO_FILE}" | cpio -id "nlib/*") || die "Unable to extract native install files from ${CPIO_FILE} to ${DEST_DIR}")
}

# Check that the crashplan directory looks like we expect
test -d "${CRASHPLAN_INSTALL_DIR}" || die "Did not find crashplan installation dir at ${CRASHPLAN_INSTALL_DIR} as expected"
test -d "${CRASHPLAN_INSTALL_DIR}/bin" || die "Did not find the crashplan bin dir at ${CRASHPLAN_INSTALL_DIR}/bin as expected"
test -d "${CRASHPLAN_INSTALL_DIR}/nlib" || die "Did not find crashplan nlib dir at ${CRASHPLAN_INSTALL_DIR}/nlib as expected"

# If we don't have the expected arguments we try the update folder
if [ "x${CRASHPLAN_INSTALL_FILE}" == "x" ]
then
    test "x${CRASHPLAN_INSTALL_DIR}" != "x" || usage

    UPDATE_FILE="$( ls -d -1 ${CRASHPLAN_INSTALL_DIR}/upgrade/*/ )upgrade.cpi"

    test -f "${UPDATE_FILE}" || die "Unable to find cpi file ${UPDATE_FILE}"

    # OK, we should be pretty safe to go
    info "All tests passed"
    info "Starting installing of native libs from update package ${UPDATE_FILE}, from ${CRASHPLAN_NATIVE_LIBS_SOURCE} files."

else
    # Check the file exists
    test -f "${CRASHPLAN_INSTALL_FILE}" || die "Unable to find file at ${CRASHPLAN_INSTALL_FILE}"

    # Check the filename matches expectations
    OK=$(echo ${CRASHPLAN_INSTALL_FILE} | sed  's/CrashPlanSmb_10\.[0-9]\+\.[0-9]\+_[0-9]\+_[0-9]\+_Linux.tgz/OK/')
    test "x${OK}" = "xOK" || die "Filename does not match expected pattern of 'CrashPlanSmb_10.X.X_XXXXXXXXXXXXXX_XX_Linux.tgz'"

    # And, check that it has the right filetype
    file "${CRASHPLAN_INSTALL_FILE}" | grep "gzip compressed data" &> /dev/null || warn "Wrong filetype for ${CRASHPLAN_INSTALL_FILE}. Should be gzip compressed data. Proceeding."

    # Extract the version number from the filename.
    VERSION=$(echo ${CRASHPLAN_INSTALL_FILE} | sed 's/.*\(10\.[0-9]\+\.[0-9]\+\).*/\1/g')	 

    # OK, we should be pretty safe to go
    info "All tests passed"
    info "Starting installing of native libs from version ${VERSION}, from ${CRASHPLAN_NATIVE_LIBS_SOURCE} files."
fi

info "Press return to proceed or Ctrl+C to abort"
read
info "Proceeding"

# Now, create a temporary directory to extract the files from the cpi archive in here.
TMPDIR_EXTRACT=$(mktemp --tmpdir -d crashplan_extract.XXXXXX) || die "Unable to create temporary directory for extracting crashplan install files into"

if [ "x${UPDATE_FILE}" != "x" ]
then
    # Extract from update file
    copyFromCpioFile "${UPDATE_FILE}" "${TMPDIR_EXTRACT}"

else
    # Unpack install file and extract from there

    # Create a temporary directory for unpacking, and unpack
    TMPDIR_INSTALL=$(mktemp --tmpdir -d crashplan_install.XXXXXX) || die "Unable to create temporary directory for unpacking crashplan install file into"
    info "Unpacking ${CRASHPLAN_INSTALL_FILE} into ${TMPDIR_INSTALL}."
    tar -zx -C "${TMPDIR_INSTALL}" -f ${CRASHPLAN_INSTALL_FILE} || die "Unable to unpack ${CRASHPLAN_INSTALL_FILE}"

    # Now, extract the files from the cpi archive. Files within files. The cpi arvhice is in TMPDIR_install
    info "Extracting native install files"

    copyFromCpioFile "${TMPDIR_INSTALL}/code42-install/CrashPlanSmb_${VERSION}.cpi" "${TMPDIR_EXTRACT}"

fi

# Set permissions on the extracted files
chmod 744 "${TMPDIR_EXTRACT}/nlib/${CRASHPLAN_NATIVE_LIBS_SOURCE}/"* || die "Unable to change permissions on the extracted files"

# These three next steps, requires root. Stopping, updating the native files, restarting.
info "Native install files extracted. Stopping crashplan service"
sudo "${CRASHPLAN_INSTALL_DIR}/bin/service.sh" stop || die "Unable to stop crashplan service"

info "Service stopped, installing nlib files"
sudo cp "${TMPDIR_EXTRACT}/nlib/${CRASHPLAN_NATIVE_LIBS_SOURCE}/"* "${CRASHPLAN_INSTALL_DIR}/nlib/" \
|| die "Unable to copy native libs from ${TMPDIR_EXTRACT}/nlib/${CRASHPLAN_NATIVE_LIBS_SOURCE}/ to ${CRASHPLAN_INSTALL_DIR}/nlib"

info "Nlib files installed, starting service"
sudo "${CRASHPLAN_INSTALL_DIR}/bin/service.sh" start || die "Unable to start crashplan service"

info "Done. Check logfile at ${CRASHPLAN_INSTALL_DIR}/log/service.log.0 for service status." 
