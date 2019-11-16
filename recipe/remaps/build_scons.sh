# this script does the following
# 1. Build up to sconsUtils
# 2. Copy the full build to a special directory, ${LSST_HOME}/stackvana_scons(Utils)
# 3. Remove scons(Utils) from eups
# 4. Patch the copied version of sconsUtils
# 5. Declare a new scons(Utils).
# 6. Remap scons(Utils) to the new one

# this sequence of steps allows people to update their local eups install
# more easily while retaining the conda integrations in sconsUtils

SCONSUTILS_VERSION="18.1.0-3-g946de54"
SCONS_VERSION="3.0.0.lsst1+5"


###################################################
# 1. Build up to sconsUtils

if [[ `uname -s` == "Darwin" ]]; then
    # scons utils is pure python
    # we are feeding it the osx system compiler since it uses itself to build
    # itself and so we need to make it happy when it finds a compiler
    CC=clang eups distrib install -v -t ${LSST_TAG} sconsUtils
else
    # scons utils is pure python
    # we are feeding it a compiler in the right spot on linux
    # since it uses itself to build itself and so we need to make it happy
    # when it finds a compiler
    # in the linux CI, there are no system compilers so this is very safe
    # the checks hopefully ensure we don't nuke another systems stuff

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

    CC=gcc eups distrib install -v -t ${LSST_TAG} sconsUtils

    if [[ "${made_prefix_gcc_link}" == "1" ]]; then
        rm ${PREFIX}/bin/gcc
    fi
    if [[ "${made_prefix_gpp_link}" == "1" ]]; then
        rm ${PREFIX}/bin/g++
    fi
fi


###################################################
# 2. Copy the full build to a special directory, ${LSST_HOME}/stackvana_sconsUtils
# this path is pretty explicit - helps the code fail when a version is bumped
if [[ `uname -s` == "Darwin" ]]; then
    sconsdir="${LSST_HOME}/stack/miniconda/DarwinX86/sconsUtils/${SCONSUTILS_VERSION}"
else
    sconsdir="${LSST_HOME}/stack/miniconda/Linux64/sconsUtils/${SCONSUTILS_VERSION}"
fi

if [ ! -d ${sconsdir} ]; then
    echo "sconsUtils version has changed! patches may need to be redone!"
    exit 1
fi

mkdir -p ${LSST_HOME}/stackvana_sconsUtils
cp -r ${sconsdir}/* ${LSST_HOME}/stackvana_sconsUtils/.

if [[ `uname -s` == "Darwin" ]]; then
    sconsdir="${LSST_HOME}/stack/miniconda/DarwinX86/scons/${SCONS_VERSION}"
else
    sconsdir="${LSST_HOME}/stack/miniconda/Linux64/scons/${SCONS_VERSION}"
fi

if [ ! -d ${sconsdir} ]; then
    echo "scons version has changed! patches may need to be redone!"
    exit 1
fi

mkdir -p ${LSST_HOME}/stackvana_scons
cp -r ${sconsdir}/* ${LSST_HOME}/stackvana_scons/.


###################################################
# 3. Remove sconsUtils from eups
eups remove -v -t ${LSST_TAG} sconsUtils
eups remove -v -t ${LSST_TAG} scons

###################################################
# 4. Patch the copied version of sconsUtils

# and then we then patch sconsUtils to work better with conda
# again I hate myself for doing this but moving on

echo "
Patching sconsUtils for conda in '${sconsdir}'..."
pushd ${LSST_HOME}/stackvana_sconsUtils

patch -p1 < ${RECIPE_DIR}/00002-sconsUtils-conda-build.patch
if [[ "$?" != "0" ]]; then
    exit 1
fi

popd


###################################################
# 5. Declare a new scons(Utils).
echo "
setupRequired(python)
envPrepend(PATH, ${PRODUCT_DIR}/bin)
" > ${LSST_HOME}/stackvana_scons/ups/scons.table

eups declare \
    -m ${LSST_HOME}/stackvana_scons/ups/scons.table \
    -r ${LSST_HOME}/stackvana_scons scons "stackvana_scons_${LSST_DM_TAG}"

echo "
# -*- python -*-

from lsst.sconsUtils import Configuration

dependencies = {}

config = Configuration(__file__, libs=[], hasSwigFiles=False)
" > ${LSST_HOME}/stackvana_sconsUtils/ups/sconsUtils.cfg

echo "
setupRequired(scons)
setupRequired(pytest_flake8)
setupRequired(pep8_naming)
setupRequired(pytest_session2file)
setupOptional(doxygen)
envPrepend(PYTHONPATH, ${PRODUCT_DIR}/python)
envPrepend(PATH, ${PRODUCT_DIR}/bin)
" > ${LSST_HOME}/stackvana_sconsUtils/ups/sconsUtils.table

eups declare \
    -m ${LSST_HOME}/stackvana_sconsUtils/ups/sconsUtils.table \
    -L ${LSST_HOME}/stackvana_sconsUtils/ups/sconsUtils.cfg \
    -r ${LSST_HOME}/stackvana_sconsUtils sconsUtils "stackvana_sconsUtils_${LSST_DM_TAG}"


###################################################
# 6. Remap scons(Utils) to the new one
mkdir -p ${EUPS_PATH}/site
echo "scons stackvana_scons_${LSST_DM_TAG}" >> ${EUPS_PATH}/site/manifest.remap
echo "sconsUtils stackvana_sconsUtils_${LSST_DM_TAG}" >> ${EUPS_PATH}/site/manifest.remap
