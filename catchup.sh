#!/bin/bash

set -xeuo pipefail

REPO=/home/p2004a/Workspace/BAR/spring
SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"

cd "$REPO"

git checkout BAR105
git submodule update
git pull upstream BAR105
git submodule update

distrobox enter spring -- "$SCRIPT_DIR/build.sh" windows last-catchup

git checkout BAR105
git submodule update

distrobox enter ubuntu18 -- "$SCRIPT_DIR/build.sh" linux last-catchup

git checkout BAR105
git submodule update

git tag last-catchup --force

git push origin

cd "$SCRIPT_DIR"
./site/env/bin/python ./site/build-site.py artifacts "$REPO"
rclone sync --progress artifacts r2bar:engine-builds-419
