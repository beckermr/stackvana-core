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
export STACKVANA_BACKUP_LSST_CONDA_ENV_NAME=${LSST_CONDA_ENV_NAME}
export LSST_CONDA_ENV_NAME=${CONDA_DEFAULT_ENV}

# clean/backup any EUPS stuff
export STACKVANA_BACKUP_EUPS_PKGROOT=${EUPS_PKGROOT}
unset EUPS_PKGROOT
export STACKVANA_BACKUP_EUPS_SHELL=${EUPS_SHELL}
unset EUPS_SHELL
export STACKVANA_BACKUP_SETUP_EUPS=${SETUP_EUPS}
unset SETUP_EUPS
export STACKVANA_BACKUP_EUPS_PATH=${EUPS_PATH}
unset EUPS_PATH
export STACKVANA_BACKUP_setup=`declare -f setup`
unset -f setup
export STACKVANA_BACKUP_unsetup=`declare -f unsetup`
unset -f unsetup

# backup the python path since eups will muck with it
export STACKVANA_BACKUP_PYTHONPATH=${PYTHONPATH}

# backup the LD paths since the DM stack will muck with them
export STACKVANA_BACKUP_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
export STACKVANA_BACKUP_DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}
export STACKVANA_BACKUP_LSST_LIBRARY_PATH=${LSST_LIBRARY_PATH}

# removing this flag since it is suspect
export STACKVANA_BACKUP_CXXFLAGS=${CXXFLAGS}
export CXXFLAGS=${CXXFLAGS//-fvisibility-inlines-hidden}

# now setup eups
source ${EUPS_DIR}/bin/setups.sh
export -f setup
export -f unsetup
export EUPS_PKGROOT="https://eups.lsst.codes/stack/src"

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

# set rpaths to resolve links properly at run time and remove a problematic flag for osx
if [[ `uname -s` == "Darwin" ]]; then
    export STACKVANA_BACKUP_LDFLAGS=${LDFLAGS}
    export LDFLAGS="${LDFLAGS//-Wl,-dead_strip_dylibs} -Wl,-rpath,${CONDA_PREFIX}/lib -L${CONDA_PREFIX}/lib"

    export STACKVANA_BACKUP_LDFLAGS_LD=${LDFLAGS_LD}
    export LDFLAGS_LD="${LDFLAGS_LD//-dead_strip_dylibs} -rpath ${CONDA_PREFIX}/lib -L${CONDA_PREFIX}/lib"
else
    stackvana_backup_and_append_envvar \
        activate \
        LDFLAGS \
        "-Wl,-rpath,${CONDA_PREFIX}/lib -Wl,-rpath-link,${CONDA_PREFIX}/lib -L${CONDA_PREFIX}/lib" \
        " "
fi
