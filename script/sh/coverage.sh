#!/usr/bin/env bash
set -e

TPMF=$(mktemp -d -t foobar.XXXXX)

if [ "$GITHUB_ACTIONS" == "true" ]; then
    forge coverage --match-path "test/unit/*.sol" --report lcov
    lcov --remove lcov.info -o lcov.info 'test/*' 'script/*'
else
    forge coverage --match-path "test/**/*.sol"
fi
