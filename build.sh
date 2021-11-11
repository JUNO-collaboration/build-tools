#!/bin/bash
# Description: A script to nightily build the JUNO offline software
# Author: Tao Lin <lintao AT ihep.ac.cn>

##############################################################################
# Necessary helpers
##############################################################################
function fatal:() {
    echo "FATAL: $*" 1>&2
    exit -1
}

##############################################################################
# Global environment variables
##############################################################################

#-----------------------------------------------------------------------------
# The top directory to hold all the daily builds.
#-----------------------------------------------------------------------------
export JUNO_NIGHTLIES_TOP=${JUNO_NIGHTLIES_TOP:-/cvmfs/juno_nightlies.ihep.ac.cn/centos7_amd64_gcc830/b}

#-----------------------------------------------------------------------------
# Even though this is a nightly build, in order to reduce the build time, 
# reuse the existing external libraries. 
#-----------------------------------------------------------------------------
export JUNOTOP=${JUNOTOP:-/cvmfs/juno.ihep.ac.cn/centos7_amd64_gcc830/Pre-Release/J21v2r0-branch}

if [ ! -d "${JUNO_NIGHTLIES_TOP}" ] ; then
    fatal: "The JUNO_NIGHTLIES_TOP ${JUNO_NIGHTLIES_TOP} does not exist"
fi

if ! touch $JUNO_NIGHTLIES_TOP/.build; then
    fatal: "The JUNO_NIGHTLIES_TOP ${JUNO_NIGHTLIES_TOP} is read-only"
fi

##############################################################################
# Helpers
##############################################################################
function get-current-weekday() {
    date +"%a" # print the abbreviated weekday name (e.g., Sun)
}

function get-workdir-path() {
    local weekday=$(get-current-weekday)
    echo $JUNO_NIGHTLIES_TOP/$weekday

}

function prepare-workdir() {
    local fullpath=$(get-workdir-path)

    if [ ! -d "$fullpath" ]; then
	mkdir $fullpath || fatal: "Failed to create $fullpath"
    fi
}

function goto-workdir() {
    pushd $(get-workdir-path) || fatal: "Failed to pushd"
}

function goback-from-workdir() {
    popd || fatal: "Failed to popd"
}

function prepare-envvar() {
    export CMTCONFIG=amd64_linux26 # deprecated: will be removed in the future
    source $JUNOTOP/setup.sh
    export WORKDIR=$(get-workdir-path)
}

function checkout-offline() {
    svn co https://juno.ihep.ac.cn/svn/offline/trunk offline
}

##############################################################################
# BUILD
##############################################################################

function buildit() {
    prepare-workdir
    goto-workdir

    prepare-envvar

    checkout-offline

    goback-from-workdir
}

buildit

