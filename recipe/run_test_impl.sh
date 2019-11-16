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

echo "attempting to build 'pex_exceptions' ..."
echo " "

if [[ `uname -s` == "Darwin" ]]; then
    echo "Making the python shim for OSX..."
    mv ${PREFIX}/bin/python3.7 ${PREFIX}/bin/python3.7.bak
    echo "#!/bin/bash
    if [[ \${LSST_LIBRARY_PATH} ]]; then
        DYLD_LIBRARY_PATH=\${LSST_LIBRARY_PATH} \\
        DYLD_FALLBACK_LIBRARY_PATH=\${LSST_LIBRARY_PATH} \\
        python3.7.bak \"\$@\"
    else
        python3.7.bak \"\$@\"
    fi
" > ${PREFIX}/bin/python3.7
    chmod u+x ${PREFIX}/bin/python3.7
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
