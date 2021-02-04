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
echo "attempting to build 'pex_exceptions' ..."
echo " "

if [[ `uname -s` == "Darwin" ]]; then
    echo "Making the python shim for OSX..."
    mv ${PREFIX}/bin/python3.8 ${PREFIX}/bin/python3.8.bak
    echo "#!/bin/bash
    if [[ \${LSST_LIBRARY_PATH} ]]; then
        DYLD_LIBRARY_PATH=\${LSST_LIBRARY_PATH} \\
        DYLD_FALLBACK_LIBRARY_PATH=\${LSST_LIBRARY_PATH} \\
        python3.8.bak \"\$@\"
    else
        python3.8.bak \"\$@\"
    fi
" > ${PREFIX}/bin/python3.8
    chmod u+x ${PREFIX}/bin/python3.8
    echo " "
fi

echo "building 'pex_exceptions' ..."
eups distrib install -v -t ${LSST_DM_TAG} pex_exceptions
echo " "

echo -n "setting up 'pex_exceptions' ... "
val=`setup -j pex_exceptions 2>&1`
if [[ ! ${val} ]]; then
    echo "worked!"
else
    echo "failed!"
    exit 1
fi

# try an import
setup pex_exceptions
python -c "import lsst.pex.exceptions"
