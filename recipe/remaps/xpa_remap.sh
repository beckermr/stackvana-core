# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_xpa/include
pushd ${LSST_HOME}/stackvana_xpa/include
for fname in prsetup.h xpa.h; do
    ln -s ${PREFIX}/include/${fname} ${fname}
done
popd

mkdir -p ${LSST_HOME}/stackvana_xpa/bin
pushd ${LSST_HOME}/stackvana_xpa/bin
for fname in xpaaccess xpaget xpainfo xpamb xpans xpaset; do
    ln -s ${PREFIX}/bin/${fname} $fname
done
popd

mkdir -p ${LSST_HOME}/stackvana_xpa/lib
pushd ${LSST_HOME}/stackvana_xpa/lib
for fname in `ls -1 ${PREFIX}/lib/libxpa.*`; do
    ln -s $fname `basename $fname`
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_xpa/ups
echo 'envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_xpa/ups/xpa.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": [],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["xpa.h"],
    libs=["xpa"],
)
' >> ${LSST_HOME}/stackvana_xpa/ups/xpa.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_xpa/ups/xpa.table \
    -r ${LSST_HOME}/stackvana_xpa xpa stackvana_xpa \
    -L ${LSST_HOME}/stackvana_xpa/ups/xpa.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "xpa stackvana_xpa" >> ${EUPS_PATH}/site/manifest.remap
