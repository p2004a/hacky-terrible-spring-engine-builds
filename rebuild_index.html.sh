#!/bin/sh

set -euo pipefail

cd artifacts

ls *.7z \
  | awk -F'-' '{ printf "%06d %s\n", $2, $0 }' \
  | sort -r \
  | awk 'BEGIN {print "<ul>"} {printf "<li><a href=\"%s\">%s</a></li>\n", $2, $2} END {print "</ul>"}' \
  > index.html
