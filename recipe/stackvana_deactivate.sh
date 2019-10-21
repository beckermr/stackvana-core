# unsetup any products to keep env clean
# topological sort makes it faster since unsetup works on deps too
pkgs=`eups list -s --topological -D 2>/dev/null | sed 's/|//g' | awk '{ print $1 }'`
while [[ $pkgs ]]; do
    for pkg in ${pkgs}; do
        if [[ ${pkg} == "eups" ]]; then
           continue
        fi
        unsetup $pkg >/dev/null 2>&1
        break
    done
    pkgs=`eups list -s --topological -D 2>/dev/null | sed 's/|//g' | awk '{ print $1 }'`
    if [[ ${pkgs} == "eups" ]]; then
        break
    fi
done

# it stops at eups so we get the rest in a list
pkgs=`eups list -s 2>/dev/null | sed 's/|//g' | awk '{ print $1 }'`
for pkg in ${pkgs}; do
    if [[ ${pkg} == "eups" ]]; then
       continue
    fi
    unsetup $pkg >/dev/null 2>&1
done

# clean out the path, removing EUPS_DIR/bin
# https://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
# we are not using the function below because this seems to mess with conda's
# own path manipulations
WORK=:$PATH:
REMOVE=":${EUPS_DIR}/bin:"
WORK=${WORK//$REMOVE/:}
WORK=${WORK%:}
WORK=${WORK#:}
export PATH=$WORK

# clean out our stuff - no need to backup or restore
unset STACKVANA_ACTIVATED
unset LSST_DM_TAG

# do the functions by hand
unset -f setup
if [[ ${STACKVANA_BACKUP_setup} ]]; then
    eval "$STACKVANA_BACKUP_setup"
fi
unset STACKVANA_BACKUP_setup

unset -f unsetup
if [[ ${STACKVANA_BACKUP_unsetup} ]]; then
    eval "$STACKVANA_BACKUP_unsetup"
fi
unset STACKVANA_BACKUP_unsetup

# remove stackvana env changes
for var in LSST_EUPS_VERSION EUPS_DIR LSST_HOME EUPS_PATH CPATH \
        LIBRARY_PATH LDFLAGS PYTHONPATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH \
        LSST_LIBRARY_PATH LSST_CONDA_ENV_NAME EUPS_PKGROOT EUPS_SHELL \
        SETUP_EUPS CXXFLAGS; do
    stackvana_backup_and_append_envvar \
        deactivate \
        $var
done

if [[ `uname -s` == "Darwin" ]]; then
    stackvana_backup_and_append_envvar \
        deactivate \
        LDFLAGS_LD
fi

unset -f stackvana_backup_and_append_envvar
