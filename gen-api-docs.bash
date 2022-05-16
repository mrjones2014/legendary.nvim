#!/usr/bin/env bash

if [[ $OSTYPE == 'darwin'* ]]; then
  ./vendor/bin/lemmy-help-macos \
    ./teal/legendary/init.tl \
    ./teal/legendary/compat/which-key.tl \
    ./teal/legendary/executor.tl \
    ./teal/legendary/filters.tl \
    ./teal/legendary/formatter.tl \
    ./teal/legendary/helpers.tl \
    ./teal/legendary/types.tl >doc/legendary-api.txt
else
  ./vendor/bin/lemmy-help-linux \
    ./teal/legendary/init.tl \
    ./teal/legendary/compat/which-key.tl \
    ./teal/legendary/executor.tl \
    ./teal/legendary/filters.tl \
    ./teal/legendary/formatter.tl \
    ./teal/legendary/helpers.tl \
    ./teal/legendary/types.tl >doc/legendary-api.txt
fi

whitespace_trimmed=$(sed 's/^[ \t]*//;s/[ \t]*$//' <doc/legendary-api.txt)
echo -e "$whitespace_trimmed" >doc/legendary-api.txt
