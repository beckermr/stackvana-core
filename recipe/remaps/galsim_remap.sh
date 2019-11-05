# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_galsim/include
pushd ${LSST_HOME}/stackvana_galsim/include
ln -s ${PREFIX}/include/galsim galsim
ln -s ${PREFIX}/include/GalSim.h GalSim.h
popd

mkdir -p ${LSST_HOME}/stackvana_galsim/bin
pushd ${LSST_HOME}/stackvana_galsim/bin
for fname in `ls -1 ${PREFIX}/bin/galsim*`; do
    ln -s $fname `basename $fname`
done
popd

mkdir -p ${LSST_HOME}/stackvana_galsim/lib
pushd ${LSST_HOME}/stackvana_galsim/lib
for fname in `ls -1 ${PREFIX}/lib/libgalsim*`; do
    ln -s $fname `basename $fname`
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_galsim/ups
echo 'setupRequired(numpy)
setupRequired(fftw)
setupRequired(eigen)

envPrepend(PYTHONPATH, ${PRODUCT_DIR})
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(PYTHONPATH, ${PRODUCT_DIR}/lib/python)
envPrepend(PATH, ${PRODUCT_DIR}/bin)
' >> ${LSST_HOME}/stackvana_galsim/ups/galsim.table

echo '
# -*- python -*-

import lsst.sconsUtils

dependencies = {
    "required": ["numpy", "fftw", "eigen"],
}

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers=["GalSim.h"],
    libs=["galsim"],
)
' >> ${LSST_HOME}/stackvana_galsim/ups/galsim.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_galsim/ups/galsim.table \
    -r ${LSST_HOME}/stackvana_galsim galsim stackvana_galsim \
    -L ${LSST_HOME}/stackvana_galsim/ups/galsim.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "galsim stackvana_galsim" >> ${EUPS_PATH}/site/manifest.remap
