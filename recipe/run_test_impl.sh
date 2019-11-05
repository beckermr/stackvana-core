#!/bin/bash
if [[ ! $LSST_HOME ]]
then
    exit 1
fi

if [[ ! $LSST_CONDA_ENV_NAME ]]
then
    exit 1
fi

if [[ ! $STACKVANA_ACTIVATED ]]
then
    exit 1
fi

echo "
environment:"
env | sort

echo "
eups runs:"
{
    eups -h
} || {
    exit 1
}

echo "
eups list:"
{
    eups list
} || {
    exit 1
}


# this should work
pkgs="doxygen boost fftw gsl log4cxx mpich sconsUtils starlink_ast coord xpa \
ndarray treecorr healpy python_psutil pep8_naming ws4py python_py python_execnet \
pytest pytest_forked pytest_xdist python_coverage pytest_cov \
pyflakes pycodestyle python_mccabe flake8 pytest_flake8 esutil requests mpi4py \
python_future sqlalchemy galsim"
allpkgs="${pkgs} apr apr_util"

echo "
making sure packages can be setup:"
{
    for pkg in ${allpkgs}; do
        echo -n "setting up '${pkg}' ... "
        val=`setup -j ${pkg} 2>&1`
        if [[ ! ${val} ]]; then
            echo "worked!"
        else
            echo "failed!"
            exit 1
        fi
    done
} || {
    exit 1
}

# and we need the right spot
echo "
making sure package locations are right:"
for pkg in ${pkgs}; do
    echo -n "testing '${pkg}' ... "
    if [[ ! `eups list -v ${pkg} | grep "lsst_home/stackvana_${pkg}"` ]]; then
        echo "failed!"
        exit 1
    else
        echo "worked!"
    fi
done

echo -n "testing 'apr' ... "
if [[ ! `eups list -v apr | grep "lsst_home/stackvana_apr_aprutil"` ]]; then
    echo "failed!"
    exit 1
else
    echo "worked!"
fi

echo -n "testing 'apr_util' ... "
if [[ ! `eups list -v apr_util | grep "lsst_home/stackvana_apr_aprutil"` ]]; then
    echo "failed!"
    exit 1
else
    echo "worked!"
fi
echo " "

echo "trying to build astshim..."
echo " "

# this shim is here to bypass SIP for running the OSX tests.
# the conda-build prefixes are very long and so the pytest
# command line tool gets /usr/bin/env put in for the prefix.
# invoking env causes SIP to be invoked and all of the DYLD_LIBRARY_PATHs
# get swallowed. Here we reinsert them right before the python executable.
if [[ `uname -s` == "Darwin" ]]; then
    echo "Making the python shim for OSX..."
    mv ${PREFIX}/bin/python3.7 ${PREFIX}/bin/python3.7.bak
    cp ${RECIPE_DIR}/python3.7 ${PREFIX}/bin/python3.7
    echo " "
fi

echo "building..."
eups distrib install -t ${LSST_DM_TAG} -v astshim
echo " "

echo -n "setting up 'astshim' ... "
val=`setup -j astshim 2>&1`
if [[ ! ${val} ]]; then
    echo "worked!"
else
    echo "failed!"
    exit 1
fi
