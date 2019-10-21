# link the headers, libs etc
mkdir -p ${LSST_HOME}/stackvana_mpich/include
pushd ${LSST_HOME}/stackvana_mpich/include
for fname in mpi.h mpicxx.h mpio.h mpiof.h; do
    ln -s ${PREFIX}/include/${fname} ${fname}
done
popd

mkdir -p ${LSST_HOME}/stackvana_mpich/bin
pushd ${LSST_HOME}/stackvana_mpich/bin
for fname in hydra_nameserver hydra_persist hydra_pmi_proxy mpic++ mpicc \
        mpichversion mpicxx mpiexec mpiexec.hydra mpirun mpivars parkill; do
    ln -s ${PREFIX}/bin/${fname} ${fname}
done
popd

mkdir -p ${LSST_HOME}/stackvana_mpich/lib
pushd ${LSST_HOME}/stackvana_mpich/lib

for fname in `ls -1 ${PREFIX}/lib/libmpi.*`; do
    ln -s $fname `basename $fname`
done

for fname in `ls -1 ${PREFIX}/lib/libmpicxx.*`; do
    ln -s $fname `basename $fname`
done

for fname in `ls -1 ${PREFIX}/lib/libmpich*`; do
    ln -s $fname `basename $fname`
done

for fname in `ls -1 ${PREFIX}/lib/libmpl.*`; do
    ln -s $fname `basename $fname`
done

for fname in `ls -1 ${PREFIX}/lib/libopa.*`; do
    ln -s $fname `basename $fname`
done

popd

mkdir -p ${LSST_HOME}/stackvana_mpich/lib/pkgconfig
pushd ${LSST_HOME}/stackvana_mpich/lib/pkgconfig
for fname in mpich.pc openpa.pc; do
    ln -s ${PREFIX}/lib/pkgconfig/${fname} ${fname}
done
popd

# deal with ups and scons integrations
mkdir -p ${LSST_HOME}/stackvana_mpich/ups
echo 'envPrepend(PATH, ${PRODUCT_DIR}/bin)
envPrepend(LD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(DYLD_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
envPrepend(LSST_LIBRARY_PATH, ${PRODUCT_DIR}/lib)
' >> ${LSST_HOME}/stackvana_mpich/ups/mpich.table

eups declare \
    -m ${LSST_HOME}/stackvana_mpich/ups/mpich.table \
    -r ${LSST_HOME}/stackvana_mpich mpich stackvana_mpich

# finally remap the library
mkdir -p ${EUPS_PATH}/site
echo "mpich stackvana_mpich" >> ${EUPS_PATH}/site/manifest.remap
