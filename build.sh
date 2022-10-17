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

function get-current-weekday() {
    date +"%a" # print the abbreviated weekday name (e.g., Sun)
}


##############################################################################
# Global environment variables
##############################################################################

#-----------------------------------------------------------------------------
# The script self
#-----------------------------------------------------------------------------
self=$(readlink -e $0 2>/dev/null)

#-----------------------------------------------------------------------------
# The top directory to hold all the daily builds.
#-----------------------------------------------------------------------------
export JUNO_NIGHTLIES_TOP=${JUNO_NIGHTLIES_TOP:-/cvmfs/juno_nightlies.ihep.ac.cn/centos7_amd64_gcc1120/b}

#-----------------------------------------------------------------------------
# Even though this is a nightly build, in order to reduce the build time, 
# reuse the existing external libraries. 
#-----------------------------------------------------------------------------
export JUNOTOP=${JUNOTOP:-/cvmfs/juno.ihep.ac.cn/centos7_amd64_gcc1120/Pre-Release/J22.2.x}

export JUNO_NIGHTLIES_WEEKDAY=${JUNO_NIGHTLIES_WEEKDAY:-$(get-current-weekday)}

##############################################################################
# Helpers
##############################################################################

function check-writable() {
    if [ ! -d "${JUNO_NIGHTLIES_TOP}" ] ; then
	fatal: "The JUNO_NIGHTLIES_TOP ${JUNO_NIGHTLIES_TOP} does not exist"
    fi

    if ! touch $JUNO_NIGHTLIES_TOP/.build; then
	fatal: "The JUNO_NIGHTLIES_TOP ${JUNO_NIGHTLIES_TOP} is read-only"
    fi
}

function get-workdir-path() {
    echo $JUNO_NIGHTLIES_TOP/$JUNO_NIGHTLIES_WEEKDAY
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
    source $JUNOTOP/setup.sh
    export WORKTOP=$(get-workdir-path)
}

function checkout-offline-svn() {
    svn co https://juno.ihep.ac.cn/svn/offline/trunk offline || fatal: "failed to checkout offline"
}

function checkout-offline-git() {
    if [ ! -d "junosw" ]; then
	git clone git@code.ihep.ac.cn:JUNO/offline/junosw.git || fatal: "failed to clone junosw"
    else
	(cd junosw && git pull) || fatal: "failed to update junosw"
    fi

}

function checkout-offline() {
    local repo=${1:-git}; shift

    case $repo in
	svn)
	    checkout-offline-svn
	    ;;
	git)
	    checkout-offline-git
	    ;;
	*)
	    ;;
    esac
}

function build-offline-svn() {
    pushd offline || fatal: "failed to pushd offline"

    ./build.sh

    popd || fatal: "faild to popd"
}

function build-offline-git() {
    pushd junosw || fatal: "failed to pushd offline"

    ./build.sh

    popd || fatal: "faild to popd"

}

function build-offline() {
    local repo=${1:-git}; shift

    case $repo in
	svn)
	    build-offline-svn
	    ;;
	git)
	    build-offline-git
	    ;;
	*)
	    ;;
    esac

}

function prepare-setupscripts() {
    local repo=${1:-git}; shift

    local projectname=junosw
    case $repo in
	svn)
	    projectname=offline
	    ;;
	*)
	    ;;
    esac

    cat <<EOF > setup.sh
export JUNOTOP=$JUNOTOP
export WORKTOP=$WORKTOP
source \$JUNOTOP/setup.sh
source \$WORKTOP/${projectname}/InstallArea/setup.sh
EOF

    cat <<EOF > setup.csh
setenv JUNOTOP $JUNOTOP
setenv WORKTOP $WORKTOP
source \$JUNOTOP/setup.csh
source \$WORKTOP/${projectname}/InstallArea/setup.csh
EOF

}

function create-latest-link() {
    pushd $JUNO_NIGHTLIES_TOP

    ln -sfn $JUNO_NIGHTLIES_WEEKDAY latest

    popd
}

##############################################################################
# BUILD
##############################################################################

function buildit() {
    check-writable

    prepare-workdir
    goto-workdir

    prepare-envvar

    checkout-offline

    build-offline

    prepare-setupscripts

    goback-from-workdir

    create-latest-link
}

##############################################################################
# DEPLOY IN CVMFS PUBLISHER
##############################################################################
#
# Note:
#      It turns out that the script could not be invoked at deploy stage.
#      Because when cvmfs_server publish the repositoy, the files under this
#      repository can not be opened. 
#
#      In order to solve this problem, the solution is creating the commands
#      on the fly, then use bash to invoke it:
#
#          bash <<< "$(bash /cvmfs/juno_nightlies.ihep.ac.cn/centos7_amd64_gcc830/b/build-tools/build.sh deployit)"
#
#-----------------------------------------------------------------------------

function deployit() {
cat <<EOF
    cvmfs_server transaction juno_nightlies.ihep.ac.cn
    [ -f "$HOME/.ssh/agent" ] && source $HOME/.ssh/agent
    export APPTAINER_BINDPATH=/cvmfs
    /cvmfs/container.ihep.ac.cn/bin/hep_container exec CentOS7 $self
    cvmfs_server publish -m "nightly build $(date)" juno_nightlies.ihep.ac.cn
EOF
}

##############################################################################
# MAIN
##############################################################################

if [ -z "$*" ]; then
    buildit
else
    $*
fi

