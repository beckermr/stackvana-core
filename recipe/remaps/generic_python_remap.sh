# location of table file
pkg_dir="${LSST_HOME}/stackvana_$1"

# deal with ups and scons integrations
mkdir -p ${pkg_dir}/ups
touch "${pkg_dir}/ups/${1}.table"

eups declare \
    -m "${pkg_dir}/ups/${1}.table" \
    -r ${pkg_dir} $1 "stackvana_$1"

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "$1 stackvana_$1" >> ${EUPS_PATH}/site/manifest.remap
