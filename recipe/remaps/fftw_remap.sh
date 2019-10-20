# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_fftw/include
pushd ${LSST_HOME}/stackvana_fftw/include
for fname in `ls -1 ${PREFIX}/include/fftw3*`; do
    ln -s $fname `basename $fname`
done
popd

mkdir -p ${LSST_HOME}/stackvana_fftw/bin
pushd ${LSST_HOME}/stackvana_fftw/bin
for fname in fftw-wisdom fftw-wisdom-to-conf fftwf-wisdom; do
    ln -s ${PREFIX}/bin/${fname} ${fname}
done
popd

mkdir -p ${LSST_HOME}/stackvana_fftw/lib
pushd ${LSST_HOME}/stackvana_fftw/lib
for fname in `ls -1 ${PREFIX}/lib/libfftw*`; do
    ln -s $fname `basename $fname`
done
popd

mkdir -p ${LSST_HOME}/stackvana_fftw/lib/pkgconfig
pushd ${LSST_HOME}/stackvana_fftw/lib/pkgconfig
for fname in `ls -1 ${PREFIX}/lib/pkgconfig/fftw*`; do
    ln -s $fname `basename $fname`
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_fftw/ups
echo 'envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_fftw/ups/fftw.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": [],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["fftw3.h"],
    libs=["fftw3","fftw3f"],
)
' >> ${LSST_HOME}/stackvana_fftw/ups/fftw.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_fftw/ups/fftw.table \
    -r ${LSST_HOME}/stackvana_fftw fftw stackvana_fftw \
    -L ${LSST_HOME}/stackvana_fftw/ups/fftw.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "fftw stackvana_fftw" >> ${EUPS_PATH}/site/manifest.remap
