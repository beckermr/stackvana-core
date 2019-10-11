# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_gsl/include
pushd ${LSST_HOME}/stackvana_gsl/include
ln -s ${PREFIX}/include/gsl gsl
popd

mkdir -p ${LSST_HOME}/stackvana_gsl/bin
pushd ${LSST_HOME}/stackvana_gsl/bin
for fname in `ls -1 ${PREFIX}/bin/gsl-*`; do
    ln -s $fname `basename $fname`
done
popd

mkdir -p ${LSST_HOME}/stackvana_gsl/lib
pushd ${LSST_HOME}/stackvana_gsl/lib
for fname in `ls -1 ${PREFIX}/lib/libgsl*`; do
    ln -s $fname `basename $fname`
done
popd

mkdir -p ${LSST_HOME}/stackvana_gsl/lib/pkgconfig
pushd ${LSST_HOME}/stackvana_gsl/lib/pkgconfig
for fname in `ls -1 ${PREFIX}/lib/pkgconfig/gsl*`; do
    ln -s $fname `basename $fname`
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_gsl/ups
echo 'envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_gsl/ups/gsl.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": [],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["gsl/gsl_rng.h"],
    libs=["gslcblas", "gsl"],
)
' >> ${LSST_HOME}/stackvana_gsl/ups/gsl.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_gsl/ups/gsl.table \
    -r ${LSST_HOME}/stackvana_gsl gsl stackvana_gsl \
    -L ${LSST_HOME}/stackvana_gsl/ups/gsl.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "gsl stackvana_gsl" >> ${EUPS_PATH}/site/manifest.remap
