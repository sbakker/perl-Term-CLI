#!/bin/bash

PROG=$0
DIR=$(dirname $PROG)

VERSION=v$(perl $DIR/get_version.pl Term::CLI)

[[ -n $VERSION ]] || exit 1

echo Releasing $VERSION

git commit -a -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push
git push --tags
