A bot for [JsPoker][0]. I store its code here so I can write tests, etc. + experiment with it without breaking the JsPoker rules.

The bot itself is at `src/challengerBot.coffee`.

You can play with the code via these scripts:

    ./watch.sh     - Watch changes in the bot and deploy in the js poker folder.
	./test.sh      - Run mocha/chai unit tests. Assign ALL_TESTS to run slooow but complete test suite.
	./bench.sh     - Pit the bot against the competition.
	./bench10.bash - Run the JSPoker test 10 times and count successes/failures.

__NOTE:__ It is currently a work in progress and thus shouldn't be expected to function well at
all.

## Versions ##

* 0.1.1 - Fixed issue with flush valuation, we should consider all card face values to avoid missing a winning hand that has lower face values than the flop.
* 0.1.0 - Won round 7 of JsPoker, highly limited post-flop analysis but full + well-tested ability to recognise hands.

[0]:https://github.com/mdp/JsPoker
