#!/bin/bash

set -euo pipefail

renice -n 15 $$
ionice -c 3 -p $$

SCRIPT_DIR="$(dirname "$(realpath -s "$0")")"

REPO="$1"
PLATFORM="$2"
if [[ "$PLATFORM" != "windows" && "$PLATFORM" != "linux" ]]; then
	echo "first argument must be correct platform"
	exit 1
fi
SYNC_FROM="$3"
BRANCH="$4"

COMMIT_SINCE="$2"
if [[ -z "$COMMIT_SINCE" ]]; then
	echo "need commit start argument"
	exit 1
fi

cd "$REPO/builddir-$PLATFORM"

function get_commits {
	for commit in $(git rev-list -n 100 $SYNC_FROM); do
		if [[ -f "$SCRIPT_DIR/built-commits/$commit-$PLATFORM" ]]; then
			return
		fi
		echo $commit
	done
}

for commit in $(get_commits | tac); do
	printf "%s: " $PLATFORM
	git -c core.pager=cat show --quiet --format=short $commit
	printf "\n"

	if ! git diff-tree --no-commit-id --name-only -r $commit | grep -v -E 'doc/' > /dev/null; then
		echo "Skipping docs only commit"
		continue
	fi

	rm -rf *
	rm -f .ninja*
	git checkout $commit --force
	git submodule update --init --recursive
	git branch -f $BRANCH
	git checkout $BRANCH
	if ./.config.sh && ninja -j 14 install; then
		NAME="engine_${PLATFORM}64_$(cat VERSION | cut -d' ' -f 1)"
		mv install "$NAME"
		7z a -r dist.7z "$NAME"
		mv dist.7z "$SCRIPT_DIR/artifacts/$NAME.7z"
		echo "ok" > "$SCRIPT_DIR/built-commits/$commit-$PLATFORM"
	else
		echo "Build failed"
		echo "fail" > "$SCRIPT_DIR/built-commits/$commit-$PLATFORM"
	fi
done
