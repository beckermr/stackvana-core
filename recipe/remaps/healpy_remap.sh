# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_healpy/ups
echo '
setupRequired(python)
setupRequired(numpy)
setupRequired(pykg_config)
setupRequired(cfitsio)
setupRequired(astropy)
' >> ${LSST_HOME}/stackvana_healpy/ups/healpy.table

eups declare \
    -m ${LSST_HOME}/stackvana_healpy/ups/healpy.table \
    -r ${LSST_HOME}/stackvana_healpy healpy stackvana_healpy

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "healpy stackvana_healpy" >> ${EUPS_PATH}/site/manifest.remap
