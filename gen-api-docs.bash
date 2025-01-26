#!/usr/bin/env bash

export LEMMY_HELP_CMD="lemmy-help"

if [ "$1" == "ci" ]; then
  curl -Lq https://github.com/numToStr/lemmy-help/releases/latest/download/lemmy-help-x86_64-unknown-linux-gnu.tar.gz | tar xz
  export LEMMY_HELP_CMD="./lemmy-help"
fi

$LEMMY_HELP_CMD -fact \
  ./lua/legendary/init.lua \
  ./lua/legendary/filters.lua \
  ./lua/legendary/toolbox.lua \
  ./lua/legendary/ui/format.lua \
  ./lua/legendary/extensions/init.lua >doc/legendary-api.txt

whitespace_trimmed=$(sed 's/^[ \t]*//;s/[ \t]*$//' <doc/legendary-api.txt)
echo -e "$whitespace_trimmed" >doc/legendary-api.txt

if [ "$1" == "ci" ]; then
  rm ./lemmy-help
fi
