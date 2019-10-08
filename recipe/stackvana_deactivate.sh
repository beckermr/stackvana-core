# unsetup any products to keep env clean
for val in `eups list -s 2> /dev/null | awk '{ print $1 }'`;
do
    unsetup $val
done

# clean out the path, removing EUPS_DIR/bin
# https://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
# we are not using the function below because this seems to mess with conda's
# own path manipulations
WORK=:$PATH:
REMOVE="${EUPS_DIR}/bin"
WORK=${WORK/:$REMOVE:/:}
WORK=${WORK%:}
WORK=${WORK#:}
export PATH=$WORK

# clean out eups/lsst stuff
unset -f setup
unset -f unsetup
unset EUPS_PKGROOT
unset EUPS_DIR
unset LSST_CONDA_ENV_NAME
unset LSST_HOME
unset BR2_PACKAGE_LIBICONV
unset EUPS_SHELL
unset SETUP_EUPS
unset STACKVANA_ACTIVATED

# remove stackvana env changes
stackvana_backup_and_append_envvar \
    deactivate \
    EUPS_PATH

stackvana_backup_and_append_envvar \
    deactivate \
    CPATH

stackvana_backup_and_append_envvar \
    deactivate \
    LIBRARY_PATH

stackvana_backup_and_append_envvar \
    deactivate \
    LDFLAGS

stackvana_backup_and_append_envvar \
    deactivate \
    CC

stackvana_backup_and_append_envvar \
    deactivate \
    PYTHONPATH

unset -f stackvana_backup_and_append_envvar
