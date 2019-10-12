# stackvana-core
[![Anaconda-Server Badge](https://anaconda.org/beckermr/stackvana-core/badges/version.svg)](https://anaconda.org/beckermr/stackvana-core) [![Anaconda-Server Badge](https://anaconda.org/beckermr/stackvana-core/badges/downloads.svg)](https://anaconda.org/beckermr/stackvana-core) [![Build Status](https://dev.azure.com/beckermr/beckermr%20conda%20channel/_apis/build/status/beckermr.stackvana-core?branchName=master)](https://dev.azure.com/beckermr/beckermr%20conda%20channel/_build/latest?definitionId=7&branchName=master)

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
[documentation](https://pipelines.lsst.io/install/newinstall.html#install-science-pipelines-packages)
for details on how to build the DM stack using ``eups``. This package runs the `eups`
installation up to installing `sconsUtils` in order to make downstream builds easier.


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

- The `eups` installation in this environment is not completely isolated from
  the outside world. Global `eups` configuration and caching done in your `~/.eups`
  directory is still visible to all environments.

- The `$EUPS_PKGROOT` environment variable is set to enable only source builds on
  Linux. On OSX systems, the build tooling is stable enough (and the OSX version used
  by the project is old enough), that it is pretty safe to also allow `eups` to use
  precompiled binaries.


## Things that I did that don't make me feel like a good person

- I have disabled `eups`'s locking mechanism to help multiple processes simultaneously
  use the same `conda` environment with this package. According to Robert Lupton, this choice should
  be fine. However, as usual with all `conda` environments, do not install packages via
  `conda` or `eups` into an environment while running code is using that same environment.
  Many thanks to Robert Lupton for pointing out how to do modify this configuration option
  elegantly!

- I have removed the builds of `doxygen`, `boost`, `fftw`, `gsl`, `apr`,
  `apr_util`, `pybind11`, and `log4cxx` from `eups` in favor of
  installing them with `conda`. I used the `manifest.remap` feature of `eups` to make
  sure this works with the existing stack installation routine.
  Many thanks to Jim Bosch for pointing out this feature of `eups`!

- I changed the first line, `#!${PREFIX}/bin/python`, in the `eups` and `eups_setup`
  scripts to `#!/usr/bin/env python`. This doesn't seem to make a difference and
  the CI services that build the stack were failing on the long prefixes used by
  `conda-build`.

- I applied a patch to the `${EUPS_DIR}/lib/eupspkg.sh` script so that it uses
  old-style `distutils` installs. (I added `--single-version-externally-managed --record record.txt`
  to `PYSETUP_INSTALL_OPTIONS` with a fallback to the old way of doing things if these command
  switches are not accepted.) This change appears to help `setuptools` find dependencies installed by `conda`
  and appears to help prevent the downloading of dependencies from `PyPi`. Instead,
  you must install the appropriate package using `conda`. `setuptools` should have been
  able to detect the dependencies in the `conda` environment in the first place, but sometimes
  this was failing for some reason unknown to me.

- I applied patches to `sconsUtils` in order to ensure it finds the `conda` compilers
  and uses the proper compiling/linking flags from the external environment. These
  patches make sure that the `conda` library prefix is always added when linking,
  that `-rpath` is always set, and that the `conda` compilers are always used.


## Known Build Issues

1. Builds of some packages on OSX from source currently fail. These are currently
   `doxygen` and `pex_exceptions`.

2. When building `astrometry.net`, you need to remove the `-I{CONDA_PREFIX}/include`
   options from `CPPFLAGS`, `CFLAGS`, `CXXFLAGS`, `DEBUG_CPPFLAGS`, `DEBUG_CFLAGS`,
   and `DEBUG_CXXFLAGS`. These options cause the header file `tic.h` to be imported
   from the wrong location.
