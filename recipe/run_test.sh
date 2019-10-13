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
if [[ `uname -s` == "Darwin" ]]; then
    pkgs="doxygen"
else
    pkgs="doxygen boost fftw gsl apr apr_util log4cxx mpich"
fi

echo "
making sure packages can be setup:"
{
    for pkg in ${pkgs}; do
        echo -n "setting up '${pkg}' ... "
        val=`setup ${pkg} 2>&1`
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
if [[ `uname -s` == "Darwin" ]]; then
    pkgs="doxygen"
else
    pkgs="doxygen boost fftw gsl log4cxx mpich"
fi

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

if [[ `uname -s` != "Darwin" ]]; then
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
fi
