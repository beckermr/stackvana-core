# we remap these in one step because the two libraries
# intermix their headers in ways that are hard to pull apart

# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_apr_aprutil/include
pushd ${LSST_HOME}/stackvana_apr_aprutil/include
ln -s ${PREFIX}/include/apr-1 apr-1
popd

mkdir -p ${LSST_HOME}/stackvana_apr_aprutil/link
pushd ${LSST_HOME}/stackvana_apr_aprutil/link
for fname in `ls -1 ${PREFIX}/lib/libapr-*`; do
    ln -s $fname `basename $fname`
done
ln -s ${PREFIX}/lib/apr.exp apr.exp

for fname in `ls -1 ${PREFIX}/lib/libaprutil-*`; do
    ln -s $fname `basename $fname`
done
ln -s ${PREFIX}/lib/aprutil.exp aprutil.exp
popd

mkdir -p ${LSST_HOME}/stackvana_apr_aprutil/lib/pkgconfig
pushd ${LSST_HOME}/stackvana_apr_aprutil/lib/pkgconfig
ln -s ${PREFIX}/lib/pkgconfig/apr-1.pc apr-1.pc
ln -s ${PREFIX}/lib/pkgconfig/apr-util-1.pc apr-util-1.pc
popd

mkdir -p ${LSST_HOME}/stackvana_apr_aprutil/bin
pushd ${LSST_HOME}/stackvana_apr_aprutil/bin
ln -s ${PREFIX}/bin/apr-1-config apr-1-config
ln -s ${PREFIX}/bin/apu-1-config apu-1-config
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_apr_aprutil/ups
echo 'envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_apr_aprutil/ups/apr.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": [],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["apr-1/apr.h"],
    libs=["apr-1"],
)
' >> ${LSST_HOME}/stackvana_apr_aprutil/ups/apr.cfg

echo 'setupRequired(apr -j stackvana_apr)
envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_apr_aprutil/ups/apr_util.table

eups declare \
    -m ${LSST_HOME}/stackvana_apr_aprutil/ups/apr.table \
    -r ${LSST_HOME}/stackvana_apr_aprutil apr stackvana_apr \
    -L ${LSST_HOME}/stackvana_apr_aprutil/ups/apr.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_apr_aprutil/ups/apr_util.table \
    -r ${LSST_HOME}/stackvana_apr_aprutil apr_util stackvana_apr_util

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "apr stackvana_apr" >> ${EUPS_PATH}/site/manifest.remap
echo "apr_util stackvana_apr_util" >> ${EUPS_PATH}/site/manifest.remap
