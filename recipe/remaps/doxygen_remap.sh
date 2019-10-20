mkdir -p ${LSST_HOME}/stackvana_doxygen/bin
pushd ${LSST_HOME}/stackvana_doxygen/bin
ln -s ../../../bin/doxygen doxygen
popd

mkdir -p ${LSST_HOME}/stackvana_doxygen/ups
echo 'envPrepend(PATH, ${PRODUCT_DIR}/bin)' >> ${LSST_HOME}/stackvana_doxygen/ups/doxygen.table
eups declare -m ${LSST_HOME}/stackvana_doxygen/ups/doxygen.table -r ${LSST_HOME}/stackvana_doxygen doxygen stackvana_doxygen

mkdir -p ${EUPS_PATH}/site
echo "doxygen stackvana_doxygen" >> ${EUPS_PATH}/site/manifest.remap
