#!/bin/bash
# Description: A script to nightily build the JUNO offline software
# Author: Tao Lin <lintao AT ihep.ac.cn>

function fatal:() {
    echo "FATAL: $*" 1>&2
    exit -1
}

JUNO_NIGHTLIES_TOP=/cvmfs/juno_nightlies.ihep.ac.cn/centos7_amd64_gcc830/b

if [ ! -d "${JUNO_NIGHTLIES_TOP}" ] ; then
    fatal: "The JUNO_NIGHTLIES_TOP ${JUNO_NIGHTLIES_TOP} does not exist"
fi

if ! touch $JUNO_NIGHTLIES_TOP/.build; then
    fatal: "The JUNO_NIGHTLIES_TOP ${JUNO_NIGHTLIES_TOP} is read-only"
fi

function get-current-weekday() {
    date +"%a" # print the abbreviated weekday name (e.g., Sun)
}



