# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_starlink_ast/include
pushd ${LSST_HOME}/stackvana_starlink_ast/include
ln -s ${PREFIX}/include/AST_ERR AST_ERR
ln -s ${PREFIX}/include/ast_err.h ast_err.h
ln -s ${PREFIX}/include/star/AST_PAR AST_PAR
ln -s ${PREFIX}/include/star/ast.h ast.h
ln -s ${PREFIX}/include/star/GRF_PAR GRF_PAR
ln -s ${PREFIX}/include/star/grf.h grf.h
ln -s ${PREFIX}/include/star/grf3d.h grf3d.h
popd

mkdir -p ${LSST_HOME}/stackvana_starlink_ast/bin
pushd ${LSST_HOME}/stackvana_starlink_ast/bin
ln -s ${PREFIX}/bin/ast_link ast_link
ln -s ${PREFIX}/bin/ast_link_adam ast_link_adam
popd

mkdir -p ${LSST_HOME}/stackvana_starlink_ast/lib
pushd ${LSST_HOME}/stackvana_starlink_ast/lib
for fname in `ls -1 ${PREFIX}/lib/libast_*`; do
    ln -s $fname `basename $fname`
done
for fname in `ls -1 ${PREFIX}/lib/libast.*`; do
    ln -s $fname `basename $fname`
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_starlink_ast/ups
echo 'envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(PATH, ${PRODUCT_DIR}/bin)
' >> ${LSST_HOME}/stackvana_starlink_ast/ups/starlink_ast.table

echo '
# -*- python -*-

import lsst.sconsUtils
import subprocess

dependencies = {}

_astLibStr = subprocess.check_output("ast_link", shell=True).decode()
# sconsUtils requires prerequisites first; ast_link gives them last
astLibs = _astLibStr.split()
astLibs.reverse()

config = lsst.sconsUtils.ExternalConfiguration(
    __file__,
    headers = ["ast.h", "ast_err.h"],
    libs = astLibs,
)
' >> ${LSST_HOME}/stackvana_starlink_ast/ups/starlink_ast.cfg

eups declare \
    -m ${LSST_HOME}/stackvana_starlink_ast/ups/starlink_ast.table \
    -r ${LSST_HOME}/stackvana_starlink_ast starlink_ast stackvana_starlink_ast \
    -L ${LSST_HOME}/stackvana_starlink_ast/ups/starlink_ast.cfg

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "starlink_ast stackvana_starlink_ast" >> ${EUPS_PATH}/site/manifest.remap
