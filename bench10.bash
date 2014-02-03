#!/usr/bin/env bash

sh init.sh
if [ "$?" -ne 0 ]; then exit 1; fi

pushd 3rdparty/JsPoker/ > /dev/null

rm -f /tmp/benches

for i in {1..10}
do
	npm test 2>&1 | grep -i '2 passing' >> /tmp/benches

	if [ $? -ne 0 ]; then
		echo -n "f"
	else
		echo -n "p"
	fi
done
echo

echo $(cat /tmp/benches | wc -l)/10

rm -f /tmp/benches

popd > /dev/null
