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
if [[ "$?" != "0" ]]; then
    exit 1
fi
# we are not using this patch right now
# it was mode to solve a problem that it does not solve :(
# patch builders.py ${RECIPE_DIR}/00003-sconsUtils-conda-for-pybind11-builder.patch
# if [[ "$?" != "0" ]]; then
#     exit 1
# fi
patch dependencies.py ${RECIPE_DIR}/00004-sconsUtils-conda-libs-always-deps.patch
if [[ "$?" != "0" ]]; then
    exit 1
fi
popd
