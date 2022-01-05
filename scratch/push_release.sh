#!/bin/bash

PROG=$0
DIR=$(dirname $PROG)

VERSION=v$(perl $DIR/get_version.pl Term::CLI)

[[ -n $VERSION ]] || exit 1

echo Committing and pushing $VERSION

git commit -a -m "Release $VERSION"
git push
