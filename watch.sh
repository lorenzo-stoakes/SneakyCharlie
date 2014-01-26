#!/usr/bin/env sh

sh init.sh
if [ "$?" -ne 0 ]; then exit 1; fi

coffee -wc -o 3rdparty/JsPoker/players/ src/challengerBot.coffee
