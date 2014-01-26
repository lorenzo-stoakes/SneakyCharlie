#!/usr/bin/env sh

sh init.sh
if [ "$?" -ne 0 ]; then exit 1; fi

mocha -w --compilers coffee:coffee-script
