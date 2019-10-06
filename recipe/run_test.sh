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

echo "eups runs:"
eups -h
echo " "

echo "environment vars:"
env | sort
echo " "

# this should run
setup doxygen

# and we need the right spot
if [[ ! `eups list -v doxygen | grep "lsst_home/stackvana_doxygen"` ]]; then
    exit 1
fi
