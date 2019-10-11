#!/bin/bash

###########################
# env control

LSST_HOME="${PREFIX}/lsst_home"

LSST_EUPS_VERSION="2.1.5"
LSST_EUPS_TARURL="https://github.com/RobertLuptonTheGood/eups/archive/${LSST_EUPS_VERSION}.tar.gz"
EUPS_DIR="${LSST_HOME}/eups/${LSST_EUPS_VERSION}"
export EUPS_PATH="${LSST_HOME}/stack/miniconda"
export EUPS_PKGROOT="https://eups.lsst.codes/stack/src"

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

if [[ ${PKG_VERSION} == *"w" ]]; then
    LSST_TAG=${PKG_VERSION%w}
    LSST_TAG="w_"${LSST_TAG//./_}
else
    LSST_TAG="v"${PKG_VERSION//./_}
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
echo "
LSST DM TAG: "${LSST_TAG}

# Install EUPS
echo "
Installing EUPS (${LSST_EUPS_VERSION})..."
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
cp ${RECIPE_DIR}/stackvana_deactivate.sh ${LSST_HOME}/stackvana_deactivate.sh

echo "
# ==================== added by build.sh in recipe build

export STACKVANA_BACKUP_LSST_EUPS_VERSION=\${LSST_EUPS_VERSION}
export LSST_EUPS_VERSION=${LSST_EUPS_VERSION}

export STACKVANA_BACKUP_LSST_HOME=\${LSST_HOME}
export LSST_HOME=\"\${CONDA_PREFIX}/lsst_home\"

export LSST_DM_TAG=${LSST_TAG}

export STACKVANA_BACKUP_EUPS_DIR=\${EUPS_DIR}
export EUPS_DIR=\"\${LSST_HOME}/eups/\${LSST_EUPS_VERSION}\"

# ==================== end of added stuff

" > ${LSST_HOME}/stackvana_activate.sh
cat ${RECIPE_DIR}/stackvana_activate.sh >> ${LSST_HOME}/stackvana_activate.sh

# copy the conda ones
for CHANGE in "activate" "deactivate"; do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

# turn off locking
mkdir -p ${EUPS_DIR}/site
echo "hooks.config.site.lockDirectoryBase = None" >> ${EUPS_DIR}/site/startup.py

# make eups use a sane path python in scripts
# the long line causes failures on linux
for fname in "eups" "eups_setup"; do
    cp ${EUPS_DIR}/bin/${fname} ${EUPS_DIR}/bin/${fname}.bak
    echo "#!/usr/bin/env python" > ${EUPS_DIR}/bin/${fname}
    tail -n +1 ${EUPS_DIR}/bin/${fname}.bak >> ${EUPS_DIR}/bin/${fname}
    chmod 755 ${EUPS_DIR}/bin/${fname}
    rm ${EUPS_DIR}/bin/${fname}.bak
done

# and now make sure eupspkg.sh doesn't install deps of its python packages
# via setuptools by accident
# we are reaching well into the source here and applying a patch
# fundamentally this is a VERY bad thing to do
# I feel ashamed to be doing this and ashamed that some other person might
# actually see this. OTOH, IDK what else to do and YOLO. /shrug
pushd ${EUPS_DIR}/lib
patch eupspkg.sh ${RECIPE_DIR}/00001-eupspkg-setuptools-patch.patch
if [[ "$?" != "0" ]]; then
    exit 1
fi
popd

# now handle some remaps
export EUPS_DIR=${EUPS_DIR}
source ${EUPS_DIR}/bin/setups.sh
export -f setup
export -f unsetup

echo "
Remapping some stuff to conda..."
# use doxygen from conda since the build is so hard and it is a binary
source ${RECIPE_DIR}/doxygen_remap.sh

# use boost from conda and live on the edge
source ${RECIPE_DIR}/boost_remap.sh ${LSST_TAG}

# ditto for fftw
source ${RECIPE_DIR}/fftw_remap.sh

# ditto for gsl
source ${RECIPE_DIR}/gsl_remap.sh

# ditto for apr & apr_util
source ${RECIPE_DIR}/apr_aprutil_remap.sh

# ditto for log4cxx
source ${RECIPE_DIR}/log4cxx_remap.sh

# ditto for pybind11
source ${RECIPE_DIR}/pybind11_remap.sh

# now install sconsUtils
# this brings most of the basic build tools in the env
echo "
Building scons+sconsUtils..."
if [[ `uname -s` == "Darwin" ]]; then
    eups distrib install -v -t ${LSST_TAG} sconsUtils
else
    # we have to do this once - the rest of the stack uses sconsUtils which
    # is patched to find the conda stuff
    # in the linux CI, there are no system compilers so this is very safe
    if [ ! -f "${PREFIX}/bin/gcc" ]; then
        ln -s ${CC} ${PREFIX}/bin/gcc
        made_prefix_gcc_link=1
    else
        made_prefix_gcc_link=0
    fi
    if [ ! -f "${PREFIX}/bin/g++" ]; then
        ln -s ${CXX} ${PREFIX}/bin/g++
        made_prefix_gpp_link=1
    else
        made_prefix_gpp_link=0
    fi
    if [ ! -f "/usr/bin/gcc" ]; then
        sudo ln -s ${PREFIX}/bin/gcc /usr/bin/gcc
        made_gcc_link=1
    else
        made_gcc_link=0
    fi
    if [ ! -f "/usr/bin/g++" ]; then
        sudo ln -s ${PREFIX}/bin/g++ /usr/bin/g++
        made_gpp_link=1
    else
        made_gpp_link=0
    fi

    CC=gcc eups distrib install -v -t ${LSST_TAG} sconsUtils

    if [[ "${made_gcc_link}" == "1" ]]; then
        sudo rm /usr/bin/gcc
    fi
    if [[ "${made_gpp_link}" == "1" ]]; then
        sudo rm /usr/bin/g++
    fi
    if [[ "${made_prefix_gcc_link}" == "1" ]]; then
        sudo rm ${PREFIX}/bin/gcc
    fi
    if [[ "${made_prefix_gpp_link}" == "1" ]]; then
        sudo rm ${PREFIX}/bin/g++
    fi
fi

# and then we then patch sconsUtils to work better with conda
# again I hate myself for doing this but moving on
# this path is pretty explicit - helps the code fail when a version is bumped
if [[ `uname -s` == "Darwin" ]]; then
    sconsdir="${LSST_HOME}/stack/miniconda/DarwinX86/sconsUtils/18.1.0-2-ga35c153/python/lsst/sconsUtils"
else
    sconsdir="${LSST_HOME}/stack/miniconda/Linux64/sconsUtils/18.1.0-2-ga35c153/python/lsst/sconsUtils"
fi
echo "
Patching sconsUtils for conda in '${sconsdir}'..."
pushd ${sconsdir}
patch state.py ${RECIPE_DIR}/00002-sconsUtils-conda-for-state.patch
patch builders.py ${RECIPE_DIR}/00003-sconsUtils-conda-for-pybind11-builder.patch
popd

# now fix up the python paths
curl -sSL https://raw.githubusercontent.com/lsst/shebangtron/master/shebangtron | ${PYTHON}

# clean out .pyc files not in the standard spots
pushd ${LSST_HOME}
if [[ `uname -s` == "Darwin" ]]; then
    find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
else
    find . -regex '^.*\(__pycache__\|\.py[co]\)$' -delete
fi
popd

unset EUPS_DIR
unset EUPS_PKGROOT
unset -f setup
unset -f unsetup
unset EUPS_SHELL
unset SETUP_EUPS
unset EUPS_PATH
