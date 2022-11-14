#!/usr/bin/env bash

lemmy-help -fact \
  ./lua/legendary/init.lua \
  ./lua/legendary/filters.lua \
  ./lua/legendary/toolbox.lua \
  ./lua/legendary/ui/format.lua \
  ./lua/legendary/integrations/which-key.lua >doc/legendary-api.txt

whitespace_trimmed=$(sed 's/^[ \t]*//;s/[ \t]*$//' <doc/legendary-api.txt)
echo -e "$whitespace_trimmed" >doc/legendary-api.txt
