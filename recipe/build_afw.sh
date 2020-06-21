#!/bin/bash

echo "=========================================================================="
env | sort
echo "=========================================================================="
echo " "

if [[ ! ${STACKVANA_ACTIVATED} ]]; then
    echo "the stackvana-core package must be activated in order to build the stack!"
    exit 1
fi

if [[ "${PREFIX}" != "${CONDA_PREFIX}" ]]; then
    echo "you need to set build/merge_build_host to True in order to build with stackvana!"
    exit 1
fi

verbose="-v"

function _report_logs {
    for fname in `compgen -G "${LSST_HOME}/stack/miniconda/*/$1/*/ups/build.log"`; do
        echo "================================================================="
        echo "================================================================="
        echo "================================================================="
        echo "================================================================="
        echo "${fname}:"
        echo "================================================================="
        echo "================================================================="
        echo " "
        cat ${fname}
        echo " "
        echo " "
    done

    for pth in "${LSST_HOME}/stack/miniconda/EupsBuildDir/*/*/build.log" \
        "${LSST_HOME}/stack/miniconda/EupsBuildDir/*/*/*/config.log" \
        "${LSST_HOME}/stack/miniconda/EupsBuildDir/*/*/*/CMakeFiles/*.log"; do

        for fname in `compgen -G $pth`; do
            echo "================================================================="
            echo "================================================================="
            echo "================================================================="
            echo "================================================================="
            echo "${fname}:"
            echo "================================================================="
            echo "================================================================="
            echo " "
            cat ${fname}
            echo " "
            echo " "
        done
    done
}

function _report_errors_and_exit {
    for pth in "${LSST_HOME}/stack/miniconda/EupsBuildDir/*/*/build.log" \
        "${LSST_HOME}/stack/miniconda/EupsBuildDir/*/*/*/config.log" \
        "${LSST_HOME}/stack/miniconda/EupsBuildDir/*/*/*/CMakeFiles/*.log"; do

        for fname in `compgen -G $pth`; do
            echo "================================================================="
            echo "================================================================="
            echo "================================================================="
            echo "================================================================="
            echo "${fname}:"
            echo "================================================================="
            echo "================================================================="
            echo " "
            cat ${fname}
            echo " "
            echo " "
        done
    done
    exit 1
}

echo "Patching sconsUtils for debugging..."
pushd ${LSST_HOME}/stackvana_sconsUtils/python/lsst/sconsUtils
patch tests.py ${RECIPE_DIR}/0001-print-test-env-sconsUtils.patch
if [[ "$?" != "0" ]]; then
    exit 1
fi
popd
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

echo "Running eups install..."
{
    eups distrib install ${verbose} -t ${LSST_DM_TAG} lsst_distrib
} || {
    _report_errors_and_exit
}
echo " "

# undo the shim
if [[ `uname -s` == "Darwin" ]]; then
    echo "Undoing the OSX python shim..."
    mv ${PREFIX}/bin/python3.7.bak ${PREFIX}/bin/python3.7
    # leave behind a symlink just in case this path propagates
    ln -s ${PREFIX}/bin/python3.7 ${PREFIX}/bin/python3.7.bak
    echo " "
fi

# fix up the python paths
# we set the python #! line by hand so that we get the right thing coming out
# in conda build for large prefixes this always has /usr/bin/env python
export SHTRON_PYTHON=${PYTHON}
echo "Fixing the python scripts with shebangtron..."
curl -sSL https://raw.githubusercontent.com/lsst/shebangtron/master/shebangtron | ${PYTHON}
echo " "

echo "Cleaning up extra data..."
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
compgen -G "${EUPS_PATH}/*/*/*/doc/html/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/doc/xml/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/share/doc/*" | xargs rm -rf
compgen -G "${EUPS_PATH}/*/*/*/share/man/*" | xargs rm -rf

# remove the global tags file since it tends to leak across envs
rm -f ${LSST_HOME}/stack/miniconda/ups_db/global.tags
