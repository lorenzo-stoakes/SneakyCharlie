#!/usr/bin/env sh

# Some initial sanity checks, ensure npm installed where we need.

if [ ! -d "node_modules" ]; then
	npm install
fi
if [ "$?" -ne 0 ]; then exit 1; fi

pushd 3rdparty/JsPoker/ > /dev/null
if [ ! -d "node_modules" ]; then npm install; fi
popd > /dev/null

coffee -c -o 3rdparty/JsPoker/players/ src/challengerBot.coffee
