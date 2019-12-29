#!/usr/bin/env bash
clear

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # https://stackoverflow.com/a/246128 (2019-12-18).
settingsFilePath="$DIR/settings.json"
pathType="file"
port=80
url=$((cat "$settingsFilePath" | jq '.url') | sed 's/^"\(.*\)"$/\1/') # Source: https://stackoverflow.com/a/9733401 (2019-12-06).
useAuthentication=true
authenticationUsername=""
authenticationPassword=""
makePrivatebin=true
privatebinTime="1week" # [5min, 10min, 1hour, 1day, 1week, 1month, 1year, never]
privatebinUrl=""
privatebinDeleteUrl=""
privatebinMsg=""

if [[ $1 ]]; then
  path="$1"
else
  echo -n "Folder or file to share. Please insert full path. Eg. /tmp/testFolder, /tmp/testFile.txt or ~/shared: "
  read path
fi
if [[ -d $path ]]; then
  pathType="dir"
elif [[ -f $path ]]; then
  pathType="file"
else
  echo "$path is not valid"
  exit 1
fi

sudo echo "I AM NOW SUDO!"

echo -n "Port (leave blank for default: $port): "
read ans
if [[ "$ans" != "" ]]; then
  port="$ans"
fi

echo -n "Use authentication (leave blank for default: y) [y/n]: "
read ans
if [[ "$ans" = "" ]] || [[ "$ans" = "y" ]]; then

  echo -n "Username (leave blank to randomnly generate one): "
  read ans
  if [[ "$ans" != "" ]]; then
    authenticationUsername="$ans"
  else
    echo -n "Generated random username: "
    randomOrgUrl="https://www.random.org/passwords/?num=1&len=8&format=plain&rnd=new"
    authenticationUsername=$(curl --silent "$randomOrgUrl")
    echo "$authenticationUsername (source: $randomOrgUrl)"
  fi
  echo -n "Password (leave blank to use username: $authenticationUsername): "
  read ans
  if [[ "$ans" == "" ]]; then
    authenticationPassword="$authenticationUsername"
  else
    authenticationPassword="$ans"
  fi

else
  useAuthentication=false

fi

echo -n "Make PrivateBin paste (leave blank for default: y) [y/n]: "
read ans
if [[ "$ans" = "" ]] || [[ "$ans" = "y" ]]; then

  echo -n "PrivateBin duration (leave blank to use default: $privatebinTime) [5min, 10min, 1hour, 1day, 1week, 1month, 1year, never]: "
  read ans
  if [[ "$ans" != "" ]]; then
    privatebinTime="$ans"
  fi

else
  makePrivatebin=false

fi

echo -e "\nYou have chosen to share the $pathType with the following settings: "
echo "- Path: $path"
echo "- Port: $port"
echo "- Use authentication: $useAuthentication"
if [[ "$useAuthentication" == true ]]; then
  echo "   - Authentication username: $authenticationUsername"
  echo "   - Authentication password: $authenticationPassword"
fi
echo "- Make PrivateBin: $makePrivatebin"
if [[ "$makePrivatebin" == true ]]; then
  echo "   - PrivateBin duration: $privatebinTime"
fi
loopRunOnce=false
while [[ "$loopRunOnce" == false ]] || [[ "$ans" == "" ]]; do
  echo -e -n "\nProceed? [y/n]: "
  read ans
  loopRunOnce=true
done

if [[ "$ans" == "y" ]]; then

  if [[ "$useAuthentication" == true ]]; then
    url="http://$authenticationUsername:$authenticationPassword@$url"
  else
    url="http://$url"
  fi
  if [[ "$port" != 80 ]]; then
    url+=":$port"
  fi
  echo -e "\nDefault url is: $url\n"
  if [[ "$makePrivatebin" == true ]]; then
    args="-o json -e $privatebinTime"
    args+=" $url"
    cmd="privatebin $args"
    response=$(eval $cmd)
    privatebinUrl=$(echo "$response" | jq '.url')
    privatebinUrl=$(echo "$privatebinUrl" | sed 's/^"\(.*\)"$/\1/') # Source: https://stackoverflow.com/a/9733401 (2019-12-06).
    privatebinDeleteUrl=$(echo "$response" | jq '.deleteUrl')
    privatebinDeleteUrl=$(echo "$privatebinDeleteUrl" | sed 's/^"\(.*\)"$/\1/')
    echo -e "PrivateBin url is: $privatebinUrl"
    echo -e "PrivateBin delete url is: $privatebinDeleteUrl\n"
  fi

  args="-p $port"
  if [[ "$pathType" == "dir" ]]; then
    args+=" -l"
  fi
  if [[ "$useAuthentication" == true ]]; then
    args+=" -a $authenticationUsername:$authenticationPassword"
  fi

  currentDate=$(date +%Y-%m-%dT%H-%M-%SZ)
  echo "Starting servefile at $currentDate: "
  cmd="sudo servefile $args \"$path\""
  eval $cmd
  currentDate=$(date +%Y-%m-%dT%H-%M-%SZ)
  echo "Ending servefile at $currentDate: "

  echo -e "\nDeleting PrivateBin..."
  curl -s "$privatebinDeleteUrl" > /dev/null

fi # if [[ "$ans" == "y" ]]; then

echo -en "\nPress enter to stop script. "
read ans
