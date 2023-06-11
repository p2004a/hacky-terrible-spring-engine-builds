#!/bin/bash

set -xeuo pipefail

REPO=/home/p2004a/Workspace/BAR/spring
SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"

cd "$REPO"

SYNC_FROM=upstream/BAR105

if [[ $# -ge 1 ]]; then
    SYNC_FROM="$1"
else
    SYNC_FROM=upstream/BAR105
    git checkout BAR105
    git submodule update --init --recursive
    git pull upstream BAR105
fi

git checkout "$SYNC_FROM"
git submodule update --init --recursive

distrobox enter spring -- "$SCRIPT_DIR/build.sh" windows last-catchup

git checkout "$SYNC_FROM"
git submodule update --init --recursive

distrobox enter ubuntu18 -- "$SCRIPT_DIR/build.sh" linux last-catchup

git checkout "$SYNC_FROM"
git branch -f BAR105
git checkout BAR105
git submodule update --init --recursive

git tag last-catchup --force

git push origin

cd "$SCRIPT_DIR"
./site/env/bin/python ./site/build-site.py artifacts "$REPO"
rclone sync --progress artifacts r2bar:engine-builds-419
