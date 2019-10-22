# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_ndarray/include
pushd ${LSST_HOME}/stackvana_ndarray/include
ln -s ${PREFIX}/include/ndarray ndarray
ln -s ${PREFIX}/include/ndarray.h ndarray.h
ln -s ${PREFIX}/include/ndarray_fwd.h ndarray_fwd.h
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_ndarray/ups
echo 'setupRequired(boost -j stackvana_boost)
setupRequired(python 3.7 [>= 3.7])
setupRequired(numpy 1.16.2 [>= 1.16.2])
setupRequired(eigen 3.3.7 [>= 3.3.7])
setupRequired(pybind11 -j stackvana_pybind11)
setupRequired(fftw -j stackvana_fftw)
envPrepend(PYTHONPATH, ${PRODUCT_DIR}/python)
' >> ${LSST_HOME}/stackvana_ndarray/ups/ndarray.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": ["boost", "numpy", "eigen", "fftw"],
    "buildRequired": ["boost_test", "swig", "pybind11"],
}

config = lsst.sconsUtils.Configuration(
    __file__,
    headers=["lsst/ndarray.h"],
    libs=[],
    hasDoxygenInclude=False,
    hasDoxygenTag=False,
    hasSwigFiles=False
)
' >> ${LSST_HOME}/stackvana_ndarray/ups/ndarray.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_ndarray/ups/ndarray.table \
    -r ${LSST_HOME}/stackvana_ndarray ndarray stackvana_ndarray \
    -L ${LSST_HOME}/stackvana_ndarray/ups/ndarray.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "ndarray stackvana_ndarray" >> ${EUPS_PATH}/site/manifest.remap
