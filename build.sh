#!/bin/bash
# Description: A script to nightily build the JUNO offline software
# Author: Tao Lin <lintao AT ihep.ac.cn>

JUNO_NIGHTLIES_TOP=/cvmfs/juno_nightlies.ihep.ac.cn/centos7_amd64_gcc830/b

function get-current-weekday() {
    date +"%a" # print the abbreviated weekday name (e.g., Sun)
}



