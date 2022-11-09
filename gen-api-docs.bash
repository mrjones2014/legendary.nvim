#!/usr/bin/env bash

if [[ $OSTYPE == 'darwin'* ]]; then
  ./vendor/bin/lemmy-help-macos \
    ./lua/legendary/init.lua \
    ./lua/legendary/filters.lua \
    ./lua/legendary/toolbox.lua \
    ./lua/legendary/ui/format.lua \
    ./lua/legendary/integrations/which-key.lua >doc/legendary-api.txt
else
  ./vendor/bin/lemmy-help-linux \
    ./lua/legendary/init.lua \
    ./lua/legendary/filters.lua \
    ./lua/legendary/toolbox.lua \
    ./lua/legendary/ui/format.lua \
    ./lua/legendary/integrations/which-key.lua >doc/legendary-api.txt
fi

whitespace_trimmed=$(sed 's/^[ \t]*//;s/[ \t]*$//' <doc/legendary-api.txt)
echo -e "$whitespace_trimmed" >doc/legendary-api.txt
