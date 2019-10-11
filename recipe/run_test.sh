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
echo "
making sure packages can be setup:"
{
    for pkg in doxygen boost fftw gsl apr apr_util log4cxx; do
        echo -n "setting up '${pkg}' ... "
        setup ${pkg}
        echo "worked!"
    done
} || {
    exit 1
}

# and we need the right spot
echo "
making sure package locations are right:"
for pkg in doxygen boost fftw gsl log4cxx pybind11; do
    if [[ ! `eups list -v ${pkg} | grep "lsst_home/stackvana_${pkg}"` ]]; then
        exit 1
    fi
done
if [[ ! `eups list -v apr | grep "lsst_home/stackvana_apr_aprutil"` ]]; then
    exit 1
fi
if [[ ! `eups list -v apr_util | grep "lsst_home/stackvana_apr_aprutil"` ]]; then
    exit 1
fi
