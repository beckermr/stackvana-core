# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_treecorr/ups
echo '
setupRequired(numpy 1.16.2 [>= 1.16.2])
setupRequired(pyyaml 5.1+2 [>= 5.1+2])
' >> ${LSST_HOME}/stackvana_treecorr/ups/treecorr.table

eups declare \
    -m ${LSST_HOME}/stackvana_treecorr/ups/treecorr.table \
    -r ${LSST_HOME}/stackvana_treecorr treecorr stackvana_treecorr

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "treecorr stackvana_treecorr" >> ${EUPS_PATH}/site/manifest.remap
