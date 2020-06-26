#!/bin/bash

echo "========================================================================="
env
echo "========================================================================="

###############################################################################
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

###############################################################################
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


###############################################################################
# actual eups build

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

# configure and patch eups

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

###############################################################################
# now install sconsUtils
# this brings most of the basic build tools into the env and lets us patch it

export EUPS_DIR=${EUPS_DIR}
source ${EUPS_DIR}/bin/setups.sh
export -f setup
export -f unsetup

echo "
Building sconsUtils..."
eups distrib install -v -t ${LSST_TAG} sconsUtils

echo "Patching sconsUtils for debugging..."
if [[ `uname -s` == "Darwin" ]]; then
    sconsdir="${LSST_HOME}/stack/miniconda/DarwinX86/sconsUtils/19.0.0-3-g1276964/python/lsst/sconsUtils"
else
    sconsdir="${LSST_HOME}/stack/miniconda/Linux64/sconsUtils/19.0.0-3-g1276964/python/lsst/sconsUtils"
fi
pushd ${sconsdir}
patch tests.py ${RECIPE_DIR}/0001-print-test-env-sconsUtils.patch
if [[ "$?" != "0" ]]; then
    exit 1
fi
patch tests.py ${RECIPE_DIR}/0002-ignore-binsrc.patch
if [[ "$?" != "0" ]]; then
    exit 1
fi
popd


###############################################################################
# now build eigen and symlink it to where it would be in conda
echo "
Building eigen and making the symlinks..."
eups distrib install -v -t ${LSST_TAG} eigen
if [[ `uname -s` == "Darwin" ]]; then
    eigendir="${LSST_HOME}/stack/miniconda/DarwinX86/eigen/3.3.7.lsst2"
else
    eigendir="${LSST_HOME}/stack/miniconda/Linux64/eigen/3.3.7.lsst2"
fi
ln -s ${PREFIX}/include/eigen3 ${eigendir}/include/eigen3
ln -s ${PREFIX}/include/Eigen ${eigendir}/include/Eigen
mkdir -p ${PREFIX}/share/pkgconfig
ln -s ${PREFIX}/share/eigen3 ${eigendir}/share/eigen3
ln -s ${PREFIX}/share/pkgconfig/eigen3.pc ${eigendir}/share/pkgconfig/eigen3.pc


###############################################################################
# now finalize the build

# # now fix up the python paths
# we set the python #! line by hand so that we get the right thing coming out
# in conda build for large prefixes this always has /usr/bin/env python
echo "
Fixing the python scripts with shebangtron..."
export SHTRON_PYTHON=${PYTHON}
curl -sSL https://raw.githubusercontent.com/lsst/shebangtron/master/shebangtron | ${PYTHON}
echo " "

# clean out .pyc files made by eups installs
# these cause problems later for a reason I don't understand
# conda remakes them IIUIC
for dr in ${LSST_HOME} ${PREFIX}/lib/python3.7/site-packages; do
    pushd $dr
    if [[ `uname -s` == "Darwin" ]]; then
        find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
    else
        find . -regex '^.*\(__pycache__\|\.py[co]\)$' -delete
    fi
    popd
done

# clean out any documentation
# this bloats the packages, is usually a ton of files, and is not needed
compgen -G "${EUPS_PATH}/*/*/*/tests/.tests/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/tests/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/bin.src/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/doc/html/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/doc/xml/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/share/doc/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/share/man/*" | xargs rm -rf

# maybe this?
echo "=================== eups list ==================="
eups list -s --topological -D --raw 2>/dev/null
echo "================================================="

# remove the global tags file since it tends to leak across envs
rm -f ${LSST_HOME}/stack/miniconda/ups_db/global.tags

unset EUPS_DIR
unset EUPS_PKGROOT
unset -f setup
unset -f unsetup
unset EUPS_SHELL
unset SETUP_EUPS
unset EUPS_PATH
