#!/usr/bin/env sh

sh init.sh
if [ "$?" -ne 0 ]; then exit 1; fi

pushd 3rdparty/JsPoker/
npm test
popd
