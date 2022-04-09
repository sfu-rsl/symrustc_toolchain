#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

function parse_dockerfile () {
(echo ; grep -B 2 FROM Dockerfile) | while read
do
    read name
    read
    read run
    "$1" "${name:2}" "$(echo "$run" | cut -d ' ' -f 4)"
done
}

function print_cmd () {
    echo 'docker build --target '"$1"' -t belcarra_'"$(echo "$1" | cut -d _ -f 2-)"' .'
}

function print_yml () {
    echo '      - name: '"$1"
    echo -n '        run: '
    print_cmd "$2"
    echo
}

function print_sh () {
    echo '# '"$1"
    print_cmd "$2"
    echo
}

fic='generated/build.yml'
cat > "$fic" <<EOF
name: Build all
on: [push, pull_request]
jobs:
  all:
    runs-on: ubuntu-20.04
    steps:
      - uses: actions/checkout@v2
EOF
parse_dockerfile print_yml >> "$fic"

fic='generated/build.sh'
cat > "$fic" <<EOF
#!/bin/bash

set -euxo pipefail

EOF
parse_dockerfile print_sh >> "$fic"