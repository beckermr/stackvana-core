#!/bin/bash

###########################
# env control

LSST_HOME="${PREFIX}/lsst_home"

LSST_EUPS_VERSION="2.1.5"
LSST_EUPS_TARURL="https://github.com/RobertLuptonTheGood/eups/archive/${LSST_EUPS_VERSION}.tar.gz"
LSST_EUPS_PKGROOT_BASE_URL="https://eups.lsst.codes/stack"
EUPS_DIR="${LSST_HOME}/eups/${LSST_EUPS_VERSION}"
EUPS_PATH="${LSST_HOME}/stack/miniconda"

if [[ `uname -s` == "Darwin" ]]; then
    EUPS_PKGROOT="${LSST_EUPS_PKGROOT_BASE_URL}/osx/10.9/clang-1000.10.44.4/miniconda3-4.5.12-1172c30|$LSST_EUPS_PKGROOT_BASE_URL/src"
else
    EUPS_PKGROOT="$LSST_EUPS_PKGROOT_BASE_URL/src"
fi
export EUPS_PKGROOT="${EUPS_PKGROOT}"

# I am hard coding these options
EUPS_PYTHON=$PYTHON  # use PYTHON in the host env for eups

NOOP_FLAG=false  # useful for debugging

# tell it where CURL is
CURL="${PREFIX}/bin/curl"
# disable curl progress meter unless running under a tty -- this is intended
# to reduce the amount of console output when running under CI
CURL_OPTS='-#'
if [[ ! -t 1 ]]; then
    CURL_OPTS='-sS'
fi


##########################
# functions

n8l::print_error() {
    >&2 echo -e "$@"
}

n8l::fail() {
    local code=${2:-1}
    [[ -n $1 ]] && n8l::print_error "$1"
    # shellcheck disable=SC2086
    exit $code
}

#
# create/update a *relative* symlink, in the basedir of the target. An existing
# file or directory will be *stomped on*.
#
n8l::ln_rel() {
    local link_target=${1?link target is required}
    local link_name=${2?link name is required}

    target_dir=$(dirname "$link_target")
    target_name=$(basename "$link_target")

    ( set -e
        cd "$target_dir"

        if [[ $(readlink "$target_name") != "$link_name" ]]; then
            # at least "ln (GNU coreutils) 8.25" will not change an abs symlink to be
            # rel, even with `-f`
            rm -rf "$link_name"
            ln -sf "$target_name" "$link_name"
        fi
    )
}


##########################
# actual build

# If no-op, prefix every install command with echo
if [[ $NOOP_FLAG == true ]]; then
    cmd="echo"
    echo "!!! NOOP_FLAG specified, no install commands will be really executed"
else
    cmd=""
fi

$cmd mkdir -p ${LSST_HOME}
$cmd pushd ${LSST_HOME}

# the install expects this symlink
$cmd n8l::ln_rel "${PREFIX}" current

# now the main script
echo " "
echo "LSST Software Stack Builder"
echo "======================================================================="
echo " "

# Install EUPS
echo "Installing EUPS (${LSST_EUPS_VERSION})..."
echo "Using python at ${EUPS_PYTHON} to install EUPS"
echo "Configured EUPS_PKGROOT: ${EUPS_PKGROOT}"

$cmd mkdir -p "$LSST_HOME/_build"
$cmd pushd "$LSST_HOME/_build"

if [[ $NOOP_FLAG == true ]]; then
    echo "downloading eups"
else
    "$CURL" "$CURL_OPTS" -L "$LSST_EUPS_TARURL" | tar xzvf -
fi

$cmd mkdir -p "eups-${LSST_EUPS_VERSION}"
$cmd pushd "eups-${LSST_EUPS_VERSION}"

$cmd mkdir -p "${EUPS_PATH}"
$cmd mkdir -p "${EUPS_DIR}"
$cmd ./configure \
    --prefix="${EUPS_DIR}" \
    --with-eups="${EUPS_PATH}" \
    --with-python="${EUPS_PYTHON}"
$cmd make install

$cmd popd  # eups-${LSST_EUPS_VERSION}
$cmd popd  # $LSST_HOME/_build

$cmd rm -rf "$LSST_HOME/_build"

# the eups install messes up permissions?
chmod -R a+r ${EUPS_DIR}
chmod -R u+w ${EUPS_DIR}

# update $EUPS_DIR current symlink
$cmd n8l::ln_rel "${EUPS_DIR}" current

# update EUPS_PATH current symlink
$cmd n8l::ln_rel "${EUPS_PATH}" current

$cmd popd  # LSST_HOME

# eups needs these dirs to be around...
$cmd mkdir -p "${EUPS_PATH}/ups_db"
$cmd mkdir -p "${EUPS_PATH}/site"
touch "${EUPS_PATH}/ups_db/.conda_keep_me_please"
touch "${EUPS_PATH}/site/.conda_keep_me_please"

# we use a separate set of activate and deactivate scripts that get sourced
# by the main conda ones
# this allows other packages which depend on this one to use them as well

# copy the stackvana activate and deactivate scripts
# these are sourced by the conda ones of the same name if needed
cp ${RECIPE_DIR}/stackvana_activate.sh ${LSST_HOME}/stackvana_activate.sh
cp ${RECIPE_DIR}/stackvana_deactivate.sh ${LSST_HOME}/stackvana_deactivate.sh

# copy the conda ones
for CHANGE in "activate" "deactivate"; do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

# turn off locking
mkdir -p ${EUPS_DIR}/site
echo "hooks.config.site.lockDirectoryBase = None" >> ${EUPS_DIR}/site/startup.py
