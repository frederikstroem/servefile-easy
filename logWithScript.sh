#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # https://stackoverflow.com/a/246128 (2019-12-18).
settingsFilePath="$DIR/settings.json"
logPath=$((cat "$settingsFilePath" | jq '.logPath') | sed 's/^"\(.*\)"$/\1/') # Source: https://stackoverflow.com/a/9733401 (2019-12-06).
mkdir "$logPath"
currentDate=$(date +%Y_%m_%dT%H_%M_%SZ)
script -f -c "$DIR/share.sh" "$logPath$currentDate.log"
