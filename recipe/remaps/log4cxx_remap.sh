# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_log4cxx/include
pushd ${LSST_HOME}/stackvana_log4cxx/include
ln -s ${PREFIX}/include/log4cxx log4cxx
popd

mkdir -p ${LSST_HOME}/stackvana_log4cxx/lib
pushd ${LSST_HOME}/stackvana_log4cxx/lib
for fname in `ls -1 ${PREFIX}/lib/liblog4cxx*`; do
    ln -s $fname `basename $fname`
done
popd

mkdir -p ${LSST_HOME}/stackvana_log4cxx/lib/pkgconfig
pushd ${LSST_HOME}/stackvana_log4cxx/lib/pkgconfig
ln -s ${PREFIX}/lib/pkgconfig/liblog4cxx.pc
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_log4cxx/ups
echo 'setupRequired(apr             -j stackvana_apr)
setupRequired(apr_util        -j stackvana_apr_util)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_log4cxx/ups/log4cxx.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": [],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["log4cxx/logger.h"],
    libs=["log4cxx"],
)
' >> ${LSST_HOME}/stackvana_log4cxx/ups/log4cxx.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_log4cxx/ups/log4cxx.table \
    -r ${LSST_HOME}/stackvana_log4cxx log4cxx stackvana_log4cxx \
    -L ${LSST_HOME}/stackvana_log4cxx/ups/log4cxx.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "log4cxx stackvana_log4cxx" >> ${EUPS_PATH}/site/manifest.remap
