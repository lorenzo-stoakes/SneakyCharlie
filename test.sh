#!/usr/bin/env sh

sh init.sh
if [ "$?" -ne 0 ]; then exit 1; fi

mocha --compilers coffee:coffee-script
