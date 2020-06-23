# # unsetup any products to keep env clean
# # topological sort makes it faster since unsetup works on deps too

# I lifted this snippet from the conda-forge eups-feedstock
# https://github.com/conda-forge/eups-feedstock/blob/master/recipe/deactivate.sh
# written by @gcomoretto @brianv0 @ktlim
# I also removed the infinite loop

pkg=`eups list -s --topological -D --raw 2>/dev/null | head -1 | cut -d'|' -f1`
while [[ -n "$pkg" && "$pkg" != "eups" ]]; do
    unsetup $pkg  > /dev/null 2>&1
    new_pkg=`eups list -s --topological -D --raw 2>/dev/null | head -1 | cut -d'|' -f1`
    if [[ ${new_pkg} == ${pkg} ]]; then
        break
    else
      pkg=${new_pkg}
    fi
done
unset pkg

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
        SETUP_EUPS SCONSUTILS_USE_CONDA_COMPILERS; do
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
