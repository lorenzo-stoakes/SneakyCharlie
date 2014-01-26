A bot for [JsPoker][0]. I store its code here so I can write tests, etc. + experiment with it without breaking the JsPoker rules.

The bot itself is at `src/challengerBot.coffee`.

You can play with the code via a triplet of scripts:

    ./watch.sh - Watch changes in the bot and deploy in the js poker folder.
	./test.sh  - Run mocha/chai unit tests.
	./bench.sh - Pit the bot against the competition.

[0]:https://github.com/mdp/JsPoker
