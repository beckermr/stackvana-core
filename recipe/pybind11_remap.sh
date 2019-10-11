# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_pybind11/include
pushd ${LSST_HOME}/stackvana_pybind11/include
ln -s ${PREFIX}/include/python3.7m/pybind11 pybind11
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_pybind11/ups
echo 'envPrepend(CMAKE_PREFIX_PATH, ${PRODUCT_DIR})
if (type == exact) {
   setupRequired(python          -j 3.7)
   setupRequired(numpy           -j 1.16.2)
   setupRequired(eigen           -j 3.3.7)
} else {
   setupRequired(python 3.7 [>= 3.7])
   setupRequired(numpy 1.16.2 [>= 1.16.2])
   setupRequired(eigen 3.3.7 [>= 3.3.7])
}
' >> ${LSST_HOME}/stackvana_pybind11/ups/pybind11.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": ["python"],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["pybind11/pybind11.h"],
    libs=[],
)
' >> ${LSST_HOME}/stackvana_pybind11/ups/pybind11.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_pybind11/ups/pybind11.table \
    -r ${LSST_HOME}/stackvana_pybind11 pybind11 stackvana_pybind11 \
    -L ${LSST_HOME}/stackvana_pybind11/ups/pybind11.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "pybind11 stackvana_pybind11" >> ${EUPS_PATH}/site/manifest.remap
