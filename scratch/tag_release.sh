#!/bin/bash

PROG=$0
DIR=$(dirname $PROG)

VERSION=v$(perl $DIR/get_version.pl Term::CLI)

[[ -n $VERSION ]] || exit 1

echo Tagging release $VERSION

git tag -m "Release $VERSION" $VERSION
git push --tags
