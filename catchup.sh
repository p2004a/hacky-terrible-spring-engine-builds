#!/bin/bash

set -xeuo pipefail

REPO=/home/p2004a/Workspace/BAR/spring-ci
SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"

cd "$REPO"

REMOTE=origin
BRANCH=BAR105

SYNC_FROM=$REMOTE/$BRANCH
git fetch $REMOTE
cd mingwlibs64
git pull
cd ../spring-static-libs
git pull
cd ..

distrobox enter spring -- "$SCRIPT_DIR/build.sh" "$REPO" windows $SYNC_FROM $BRANCH
distrobox enter ubuntu18 -- "$SCRIPT_DIR/build.sh" "$REPO" linux $SYNC_FROM $BRANCH

git -c advice.detachedHead=false checkout "$SYNC_FROM" --force
git branch -f $BRANCH
git checkout $BRANCH
git submodule update --init --recursive

cd "$SCRIPT_DIR"

SITE_HASH_BEFORE=$(md5sum artifacts/index.html | cut -d' ' -f 1)
./site/env/bin/python ./site/build-site.py artifacts "$REPO"
SITE_HASH_AFTER=$(md5sum artifacts/index.html | cut -d' ' -f 1)

if [[ "$SITE_HASH_BEFORE" != "$SITE_HASH_AFTER" ]]; then
    rclone sync --progress artifacts r2bar:engine-builds-419
fi
