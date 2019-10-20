# link the headers and libs
mkdir -p ${LSST_HOME}/stackvana_boost/include
pushd ${LSST_HOME}/stackvana_boost/include
ln -s ${PREFIX}/include/boost boost
popd

mkdir -p ${LSST_HOME}/stackvana_boost/lib
pushd ${LSST_HOME}/stackvana_boost/lib
for fname in `ls -1 ${PREFIX}/lib/libboost*`; do
    ln -s $fname `basename $fname`
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_boost/ups
echo 'setupOptional("python")
envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_boost/ups/boost.table

pushd ${LSST_HOME}/stackvana_boost
git clone -b ${1//_/.} --depth 1 https://github.com/lsst/boost.git lsst_boost_github_repo
popd

eups declare \
    -m ${LSST_HOME}/stackvana_boost/ups/boost.table \
    -r ${LSST_HOME}/stackvana_boost boost stackvana_boost \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_filesystem.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_math.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_program_options.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_regex.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_serialization.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_system.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_test.cfg \
    -L ${LSST_HOME}/stackvana_boost/lsst_boost_github_repo/ups/boost_thread.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "boost stackvana_boost" >> ${EUPS_PATH}/site/manifest.remap
