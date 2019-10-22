# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_coord/ups
echo '
setupRequired(python 3.7 [>= 3.7])
setupRequired(numpy 1.16.2 [>= 1.16.2])
' >> ${LSST_HOME}/stackvana_coord/ups/coord.table

eups declare \
    -m ${LSST_HOME}/stackvana_coord/ups/coord.table \
    -r ${LSST_HOME}/stackvana_coord coord stackvana_coord

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "coord stackvana_coord" >> ${EUPS_PATH}/site/manifest.remap
