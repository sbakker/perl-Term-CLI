#!/bin/bash
#
# Build a .deb package for Term::CLI, using the pre-packaged
# debian packaging files in ./pkg/debian.

if [[ ! -d ./pkg/debian || ! -f Makefile.PL ]]; then
cat <<EOF >&2
** ERROR **

This script needs to be executed in the top-level source directory,
i.e. the one containing the "Makefile.PL" file and "pkg" directory.
EOF
fi

TOP=$(pwd)
#trap "cd $TOP; rm -rf $TOP/.build" 0
trap 'echo "** Interrupted">&2; exit 1' 1 2 3 15

# Build a release tarball
perl Makefile.PL
make DISTVNAME=build dist

# Create a clean .build environment.
rm -rf $TOP/.build
mkdir $TOP/.build

# Unpack release tarball in build directory.
mv $TOP/build.tar.gz $TOP/.build
cd $TOP/.build
tar -xzf build.tar.gz

# Sync the debian packaging files.
rm -rf $TOP/.build/build/debian
rsync -av $TOP/pkg/debian $TOP/.build/build

# Build the package.
cd $TOP/.build/build
fakeroot dpkg-buildpackage -b

# Copy the built package to the parent dir of $TOP,
# simulating a dpkg-buildpackage in the $TOP dir.
mv $TOP/.build/libterm-cli-perl_* ..

exit 0
