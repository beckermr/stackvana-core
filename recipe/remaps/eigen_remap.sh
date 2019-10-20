# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_eigen/include
pushd ${LSST_HOME}/stackvana_eigen/include
ln -s ${PREFIX}/include/eigen3 eigen3
# eups installs have these
ln -s ${PREFIX}/include/eigen3/Eigen Eigen
ln -s ${PREFIX}/include/eigen3/signature_of_eigen3_matrix_library signature_of_eigen3_matrix_library
ln -s ${PREFIX}/include/eigen3/unsupported unsupported
popd

mkdir -p ${LSST_HOME}/stackvana_eigen/share/pkgconfig
pushd ${LSST_HOME}/stackvana_eigen/share
ln -s ${PREFIX}/share/eigen3 eigen3
popd
pushd ${LSST_HOME}/stackvana_eigen/share/pkgconfig
ln -s ${PREFIX}/share/pkgconfig/eigen3.pc eigen3.pc
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_eigen/ups
touch ${LSST_HOME}/stackvana_eigen/ups/eigen.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["Eigen/Core"],
    libs=[],
)
' >> ${LSST_HOME}/stackvana_eigen/ups/eigen.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_eigen/ups/eigen.table \
    -r ${LSST_HOME}/stackvana_eigen eigen stackvana_eigen \
    -L ${LSST_HOME}/stackvana_eigen/ups/eigen.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "eigen stackvana_eigen" >> ${EUPS_PATH}/site/manifest.remap
