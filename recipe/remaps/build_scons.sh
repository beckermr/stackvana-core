# this script does the following
# 1. Build up to sconsUtils
# 2. Copy the full build to a special directory, ${LSST_HOME}/stackvana_sconsUtils
# 3. Remove sconsUtils from eups
# 4. Patch the copied version of sconsUtils
# 5. Declare a new sconsUtils.
# 6. Remap sconsUtils to the new one

# this sequence of steps allows people to update their local eups install
# more easily while retaining the conda integrations in sconsUtils

SCONSUTILS_VERSION="18.1.0-3-g946de54"


###################################################
# 1. Build up to sconsUtils

if [[ `uname -s` == "Darwin" ]]; then
    # scons utils is pure python
    # we are feeding it the osx system compiler since it uses itself to build
    # itself and so we need to make it happy when it finds a compiler
    CC=clang eups distrib install -v -t ${LSST_TAG} -o sconsUtils
    CC=clang eups distrib install -v -t w_2019_44 -j sconsUtils
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

    CC=gcc eups distrib install -v -t ${LSST_TAG} -o sconsUtils
    CC=gcc eups distrib install -v -t w_2019_44 -j sconsUtils

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
    globbed_sconsdir=`compgen -G "${LSST_HOME}/stack/miniconda/*/sconsUtils*"`
    echo "sconsUtils version has changed! patches may need to be redone!"
    echo "found directory: ${globbed_sconsdir}"
    exit 1
fi

mkdir -p ${LSST_HOME}/stackvana_sconsUtils
cp -r ${sconsdir}/* ${LSST_HOME}/stackvana_sconsUtils/.


###################################################
# 3. Remove sconsUtils from eups
eups remove -v -t w_2019_44 sconsUtils


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
# 5. Declare a new sconsUtils.
eups declare \
    -m ${LSST_HOME}/stackvana_sconsUtils/ups/sconsUtils.table \
    -L ${LSST_HOME}/stackvana_sconsUtils/ups/sconsUtils.cfg \
    -r ${LSST_HOME}/stackvana_sconsUtils sconsUtils "${SCONSUTILS_VERSION}"


###################################################
# 6. Remap sconsUtils to the new one
mkdir -p ${EUPS_PATH}/site
echo "sconsUtils ${SCONSUTILS_VERSION}" >> ${EUPS_PATH}/site/manifest.remap
