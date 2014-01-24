A bot for [JsPoker][0]. I store its code here so I can write tests, etc. + experiment with it without breaking the JsPoker rules.

To set up you need to `npm install` in the JsPoker submodule directory:-

    pushd 3rdparty/JsPoker
	npm install
	popd

Now run `./watch.sh` to monitor changes in the `challengerBot.coffee` file.

[0]:https://github.com/mdp/JsPoker
