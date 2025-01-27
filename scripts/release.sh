#!/usr/bin/env bash

BUMP=$(git cliff --bump -o CHANGELOG.md 2>&1)

if echo "$BUMP" | grep -q "There is nothing to bump."; then
    echo "nothing to release"
    exit 1
fi

VERSION=$(git cliff --bumped-version)

git add CHANGELOG.md
git commit -m "chore(release): prepare for $VERSION"
git tag $VERSION
