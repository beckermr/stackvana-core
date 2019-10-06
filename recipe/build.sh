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

mkdir -p ${LSST_HOME}
pushd ${LSST_HOME}

# the install expects this symlink
n8l::ln_rel "${PREFIX}" current

# now the main script
echo " "
echo "LSST Software Stack Builder"
echo "======================================================================="
echo " "

# Install EUPS
echo "Installing EUPS (${LSST_EUPS_VERSION})..."
echo "Using python at ${EUPS_PYTHON} to install EUPS"
echo "Configured EUPS_PKGROOT: ${EUPS_PKGROOT}"

mkdir -p "$LSST_HOME/_build"
pushd "$LSST_HOME/_build"

"$CURL" "$CURL_OPTS" -L "$LSST_EUPS_TARURL" | tar xzvf -

mkdir -p "eups-${LSST_EUPS_VERSION}"
pushd "eups-${LSST_EUPS_VERSION}"

mkdir -p "${EUPS_PATH}"
mkdir -p "${EUPS_DIR}"
./configure \
    --prefix="${EUPS_DIR}" \
    --with-eups="${EUPS_PATH}" \
    --with-python="${EUPS_PYTHON}"
make install

popd  # eups-${LSST_EUPS_VERSION}
popd  # $LSST_HOME/_build

rm -rf "$LSST_HOME/_build"

# the eups install messes up permissions?
chmod -R a+r ${EUPS_DIR}
chmod -R u+w ${EUPS_DIR}

# update $EUPS_DIR current symlink
n8l::ln_rel "${EUPS_DIR}" current

# update EUPS_PATH current symlink
n8l::ln_rel "${EUPS_PATH}" current

popd  # LSST_HOME

# eups needs these dirs to be around...
mkdir -p "${EUPS_PATH}/ups_db"
mkdir -p "${EUPS_PATH}/site"
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

# patch doxygn since the build is so hard and it is a binary
# now setup eups
cat ${EUPS_DIR}/bin/setups.sh

export EUPS_DIR=${EUPS_DIR}
source ${EUPS_DIR}/bin/setups.sh
export -f setup
export -f unsetup

mkdir -p ${LSST_HOME}/stackvana_doxygen/bin
pushd ${LSST_HOME}/stackvana_doxygen/bin
ln -s ../../../bin/doxygen doxygen
popd

eups declare -m none -r ${LSST_HOME}/stackvana_doxygen doxygen stackvana_doxygen

mkdir -p ${EUPS_PATH}/site
echo "doxygen stackvana_doxygen" >> ${EUPS_PATH}/site/manifest.remap

unset EUPS_DIR
