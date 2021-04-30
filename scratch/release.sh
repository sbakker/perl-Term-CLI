#!/bin/bash

VERSION=v$(perl scratch/get_version.pl Term::CLI)
git commit -a -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push
git push --tags
