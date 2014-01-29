A bot for [JsPoker][0]. I store its code here so I can write tests, etc. + experiment with it without breaking the JsPoker rules.

The bot itself is at `src/challengerBot.coffee`.

You can play with the code via a triplet of scripts:

    ./watch.sh - Watch changes in the bot and deploy in the js poker folder.
	./test.sh  - Run mocha/chai unit tests. Assign ALL_TESTS to run slooow but complete test suite.
	./bench.sh - Pit the bot against the competition.

__NOTE:__ It is currently a work in progress and thus shouldn't be expected to function well at
all.

[0]:https://github.com/mdp/JsPoker
