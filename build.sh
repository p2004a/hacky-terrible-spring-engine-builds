#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"

PLATFORM="$1"
if [[ "$PLATFORM" == "windows" ]]; then
	BUILD_PATH=/home/p2004a/Workspace/BAR/spring/builddir-win
elif [[ "$PLATFORM" == "linux" ]]; then
	BUILD_PATH=/home/p2004a/Workspace/BAR/spring/builddir-static-18
else
	echo "first argument must be correct platform"
	exit 1
fi

COMMIT_SINCE="$2"
if [[ -z "$COMMIT_SINCE" ]]; then
	echo "need commit start argument"
	exit 1
fi

cd $BUILD_PATH

for commit in $(git rev-list "$COMMIT_SINCE"..HEAD); do
	printf "%s: " $PLATFORM
	git -c core.pager=cat show --quiet --format=short $commit
	printf "\n"

	if ! git diff-tree --no-commit-id --name-only -r $commit | grep -v -E 'doc/' > /dev/null; then
		echo "Skipping docs only commit"
		continue
	fi

	rm -rf *
	rm -f .ninja*
	git checkout $commit
	git submodule update
	./.config.sh
	if ninja -j 14 install; then
		NAME="engine_${PLATFORM}64_$(cat VERSION | cut -d' ' -f 1)"
		mv install "$NAME"
		7z a -r dist.7z "$NAME"
		mv dist.7z "$SCRIPT_DIR/artifacts/$NAME.7z"
	else
		echo "Build failed"
	fi
done
