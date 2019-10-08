# note that before calling this script, you must check that eups has not already
# been activated. for example, the conda activate script for stackvana-core is
#
#     if [[ ! ${STACKVANA_ACTIVATED} ]]; then
#         source ${CONDA_PREFIX}/lsst_home/stackvana_activate.sh
#     fi
#

# a flag to indicate stackvana is activated
export STACKVANA_ACTIVATED=1

# LSST vars
export LSST_HOME="${CONDA_PREFIX}/lsst_home"
export LSST_CONDA_ENV_NAME=${CONDA_DEFAULT_ENV}

# clean out the EUPS path so we have only one env
export STACKVANA_BACKUP_EUPS_PATH=${EUPS_PATH}
unset EUPS_PATH

# backup the python path since eups will muck with it
export STACKVANA_BACKUP_PYTHONPATH=${PYTHONPATH}

# make scons happy
if [[ `uname -s` == "Darwin" ]]; then
    export STACKVANA_BACKUP_CC=${CC}
    export CC=clang
else
    export STACKVANA_BACKUP_CC=${CC}
    export CC=gcc
fi

# now setup eups
export EUPS_DIR="${LSST_HOME}/eups/2.1.5"
source ${EUPS_DIR}/bin/setups.sh
export -f setup
export -f unsetup
LSST_EUPS_PKGROOT_BASE_URL="https://eups.lsst.codes/stack"
if [[ `uname -s` == "Darwin" ]]; then
    EUPS_PKGROOT="${LSST_EUPS_PKGROOT_BASE_URL}/osx/10.9/clang-1000.10.44.4/miniconda3-4.5.12-1172c30|$LSST_EUPS_PKGROOT_BASE_URL/src"
else
    EUPS_PKGROOT="$LSST_EUPS_PKGROOT_BASE_URL/src"
fi
export EUPS_PKGROOT="${EUPS_PKGROOT}"

# finally setup env so we can build packages
function stackvana_backup_and_append_envvar() {
    local way=$1
    local envvar=$2

    if [[ ${way} == "activate" ]]; then
        local appval=$3
        local appsep=$4
        eval oldval="\$${envvar}"

        eval "export STACKVANA_BACKUP_${envvar}=\"${oldval}\""
        if [[ ! ${oldval} ]]; then
            eval "export ${envvar}=\"${appval}\""
        else
            eval "export ${envvar}=\"${oldval}${appsep}${appval}\""
        fi
    else
        eval backval="\$STACKVANA_BACKUP_${envvar}"

        if [[ ! ${backval} ]]; then
            eval "unset ${envvar}"
        else
            eval "export ${envvar}=\"${backval}\""
        fi
        eval "unset STACKVANA_BACKUP_${envvar}"
    fi
}

export -f stackvana_backup_and_append_envvar

# conda env includes are searched after the command line -I paths
stackvana_backup_and_append_envvar \
    activate \
    CPATH \
    "${CONDA_PREFIX}/include" \
    ":"

# add conda env libraries for linking
stackvana_backup_and_append_envvar \
    activate \
    LIBRARY_PATH \
    "${CONDA_PREFIX}/lib" \
    ":"

# set rpaths to resolve links properly at run time
stackvana_backup_and_append_envvar \
    activate \
    LDFLAGS \
    "-Wl,-rpath,${CONDA_PREFIX}/lib -L${CONDA_PREFIX}/lib" \
    " "
