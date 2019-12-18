#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # https://stackoverflow.com/a/246128 (2019-12-18).
#screen ~/scripts-commands-and-settings/share/share.sh
screen "$DIR/logWithScript.sh"
