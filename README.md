# stackvana-core

core build tooling for stackvana

#### DISCLAIMER: This installation of the DM stack is not supported, promised to work, or promised to be bug free in any way. You use this package at your own risk.


## Usage

It is best to create a brand new `conda` environment for the DM stack.

```bash
conda create -c beckermr -n mystack stackvana-core
```

The command above will create a `conda` environment with all of the dependencies
and tools you need to actually build the DM stack. In general, you should consult
the LSST DM
[documentation](https://pipelines.lsst.io/v/v18_1_0/install/newinstall.html#install-science-pipelines-packages)
for details on how to build the DM stack using ``eups``.


## Notes on the `conda` packaging of `eups` and the `conda` build tooling

- The builds are configured to use the compilers provided by `conda`. On linux,
  these are the GNU compilers. On OSX, these are a combination of the LLVM `clang`
  compilers and the GNU fortran compiler.

- This `conda` package has been carefully constructed to activate `eups` (via
  sourcing `${EUPS_DIR}/bin/setups.sh`) and set the needed environment variables
  to enable `eups` to build packages against the `conda` environment. This activation
  happens when the `conda` environment is activated.

- Similarly, when the `conda` environment is deactivated, all of the changes made by
  this package, and those made by activating `eups`, are removed, leaving the original
  environment intact.

- I have disabled `eups`'s locking mechanism to help multiple processes simultaneously
  use the same `conda` environment with this package. According to RKL, this choice should
  be fine. However, as usual with all `conda` environments, do not install packages via
  `conda` or `eups` into an environment while running code is using that same environment.

- The `eups` installation in this environment is not completely isolated from
  the outside world. Global `eups` configuration and caching done in your `~/.eups`
  directory is still visible to all environments.

- The `$EUPS_PKGROOT` environment variable is set to enable only source builds on
  Linux. On OSX systems, the build tooling is stable enough (and the OSX version used
  by the project is old enough), that it is pretty safe to also allow `eups` to use
  precompiled binaries.


## Known Build Issues

1. For some packages in the DM stack, you will need to set `LD_LIBARY_PATH` to
   point to `${CONDA_PREFIX}/lib` when executing the `eups` installation,

   ```bash
   $ LD_LIBRARY_PATH=${CONDA_PREFIX}/lib eups distrib install -t v18_1_0 log
   ```

   Only the `log` package is known to require this at the moment.

2. Builds of some packages on OSX currently fail.
