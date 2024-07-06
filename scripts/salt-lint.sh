#!/bin/sh

## SPDX-FileCopyrightText: 2023 Benjamin Grande M. S. <ben.grande.b@gmail.com>
##
## SPDX-License-Identifier: AGPL-3.0-or-later

# shellcheck disable=SC2086
set -eu

command -v git >/dev/null || { echo "Missing program: git" >&2; exit 1; }
cd "$(git rev-parse --show-toplevel)" || exit 1
./scripts/requires-program.sh salt-lint

find_tool="$(./scripts/best-program.sh fd fdfind find)"
possible_conf="${PWD}/.salt-lint"
conf=""
test -f "${possible_conf}" && conf="-c ${possible_conf}"

if test -n "${1-}"; then
  files=""
  for f in "$@"; do
    test -f "$f" || continue
    extension="${f##*.}"
    case "$extension" in
      top|sls) files="$files $f";;
      *) continue;;
    esac
  done
  test -n "$files" || exit 0
  exec salt-lint ${conf} ${files}
fi

case "${find_tool}" in
  fd|fdfind) files="$(${find_tool} . minion.d/ --extension=conf) $(${find_tool} . salt/ --max-depth=2 --type=f --extension=sls --extension=top | sort -d)";;
  find) files="$(find minion.d/ -type f -name "*.conf") $(find salt/* -maxdepth 2 -type f \( -name '*.sls' -o -name '*.top' \) | sort -d)";;
esac

exec salt-lint ${conf} ${files}
