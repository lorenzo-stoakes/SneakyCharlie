_ = require('lodash')
fs = require('fs')
require('chai').should()

Charlie = require('../src/challengerBot')

# Use example game data from JsPoker README.
_gameData = JSON.parse(fs.readFileSync(__dirname + '/GameData.json'))

# If ALL_TESTS not set run a subset in sane time, otherwise it takes several seconds.
QUICK = !process.env.ALL_TESTS

# The number of times we repeat some randomly generated tests.
TEST_COUNT = 1e3

allFaces = _.map([ 2..9 ], (n) -> '' + n)
allFaces = allFaces.concat([ 'T', 'J', 'Q', 'K', 'A' ])
allSuits = [ 'h', 'd', 's', 'c' ]

allHands = []
# Populate allHands. By nature of this loop, will always be in sorted order.
for face1, i in allFaces
	for face2 in allFaces[i...]
		for suit1, j in allSuits
			for suit2 in allSuits[j...]
				# Ignore duplicates.
				continue if face1 == face2 and suit1 == suit2

				allHands.push(face1 + suit1 + face2 + suit2)

# Helper function to do that grand old js abomination task of extracting an array from an
# arguments object.
argsToArray = (args) ->
	return Array.prototype.slice.call(args, 0)

# Helper function to generate all combinations of n elements of input set.
combin = (set, n) ->
	len = set.length

	return null if n <= 0 or len == 0

	ret = []

	# The number of elements prefixing results.
	prefixLen = len - n + 1

	for el, i in set[...prefixLen]
		for suffix in combin(set[i + 1...], n - 1) ? [[]]
			ret.push([ el ].concat(suffix))

	return ret

# Helper function to generate permutations choosing n elements.
permute = (set, n, allowDupes=false) ->
	return ([ x ] for x in set) if n == 1
	return set if set.length <= 1

	ret = []

	for el, i in set
		set.splice(i, 1) if !allowDupes
		for list in permute(set, n-1, allowDupes)
			ret.push([ el ].concat(list))
		set.splice(i, 0, el) if !allowDupes

	return ret

# Helper function to generate a string repeating the character chr n times.
repeat = (chr, n) ->
	return new Array(n + 1).join(chr)

# Helper function to set charlie up to have the specified hand.
# TODO: Move to Charlie himself.
setCharlie = (charlie, hand, community = '') ->
	charlie.state.community = community

	if community == ''
		charlie.state.communitySuits = ''
		charlie.state.communityVals = []
	else
		# TODO: De-duplicate from Charlie.analyse.
		charlie.state.communitySuits = (s for s in community[1...] by 2).sort().join('')
		charlie.state.communityVals = (charlie.handVals[v] for v in community by 2)

	charlie.state.hand = hand

	[ face1, suit1, face2, suit2 ] = hand

	charlie.state.faces = faces = face1 + face2
	charlie.state.suits = suits = suit1 + suit2

	# Guaranteed to be in order.
	charlie.state.vals = [ charlie.handVals[face1], charlie.handVals[face2] ]

	charlie.state.monster = faces in [ 'AA', 'KK' ]
	charlie.state.pair = face1 == face2

# Helper function to get a copy of game data.
getGameData = ->
	# Deep clones objects.
	return _.clone(_gameData, true)

# Helper function to Helper function designed to avoid running excessive numbers of test cases.
# Randomly adds extra cards so we check 5,6,7-card hands 1/3 of the time each.
addExtra = (vals, noDupes = false, count = 2) ->
	valHash = {}
	if noDupes
		valHash[v] = true for v in vals

	extras = _.random(0, count)
	for i in [ 0...extras ]
		n = _.random(2, 14)

		if noDupes
			while valHash[n]
				n = _.random(2, 14)

			valHash[n] = true

		vals.push(n)

describe "Charlie's function", ->
	describe 'analyse', ->
		charlie = new Charlie()
		analyse = charlie.analyse.bind(charlie)

		sortNumArgs = null
		calcPosArgs = null
		getBigBlindArgs = null

		# Stub out some functions.

		charlie.calcPos = ->
			calcPosArgs = argsToArray(arguments)

			return charlie.pos.co

		charlie.getBigBlind = ->
			getBigBlindArgs = argsToArray(arguments)

			return 17

		it 'is a function', ->
			analyse.should.be.a('function')

		gameData = getGameData()

		analyse(gameData)
		{ state } = charlie

		it 'should set betting equal to input betting', ->
			state.betting.should.eql(gameData.betting)

		it 'should set the correct community cards', ->
			state.community.should.equal('5c9sKh')

		it 'should set the correct community suits', ->
			state.communitySuits.should.equal('chs')

		it 'should set the correct community vals', ->
			state.communityVals.should.eql([ 5, 9, 13 ])

		it 'should have set the correct hand', ->
			state.hand.should.equal('4sJd')

		it 'should have set the correct faces', ->
			state.faces.should.equal('4J')

		# TODO: Perhaps sort?
		it 'should have set the correct suits', ->
			state.suits.should.equal('sd')

		it 'should have set the correct number of chips', ->
			state.chips.should.equal(490)

		it 'should have set the correct vals', ->
			state.vals.should.eql([ 4, 11 ])

		it 'should have called calcPos with expected inputs', ->
			calcPosArgs.should.eql([ 6, 4 ])

		it 'should have assigned pos using the result from calcPos', ->
			state.pos.should.equal(charlie.pos.co)

		it 'should have called getBigBlind with expected inputs', ->
			getBigBlindArgs.should.eql([ gameData.players ])

		it 'should have assigned bb with the result from getBigBlind', ->
			state.bb.should.equal(17)

		it 'should have marked this postflop play as playable', ->
			state.playable.should.equal(true)

		it "shouldn't mark the hand as a monster", ->
			state.monster.should.equal(false)

		it "shouldn't mark the hand as a pair", ->
			state.pair.should.equal(false)

		it 'should have set the correct round', ->
			state.round.should.equal('flop')

		it 'should have set the correct poker hand', ->
			state.pokerHand.should.equal(charlie.pokerHand.highCard)

		it 'should have set the correct hand value', ->
			state.pokerVals.should.eql([ 13 ])

	describe 'analyse rounds', ->
		charlie = new Charlie()
		analyse = charlie.analyse.bind(charlie)
		gameData = getGameData()
		gameData.state = 'pre-flop'
		analyse(gameData)
		{ state } = charlie

		it 'should set round, previousRound and bettingRound state values correctly', ->
			_.isNull(state.previousRound).should.equal(true)
			state.round.should.equal('pre-flop')
			state.bettingRound.should.equal(1)

			analyse(gameData)

			state.previousRound.should.equal('pre-flop')
			state.round.should.equal('pre-flop')
			state.bettingRound.should.equal(2)

			gameData.state = 'flop'

			analyse(gameData)

			state.previousRound.should.equal('pre-flop')
			state.round.should.equal('flop')
			state.bettingRound.should.equal(1)

	describe 'calcPos', ->
		charlie = new Charlie()
		{ pos } = charlie
		calcPos = charlie.calcPos.bind(charlie)

		it 'is a function', ->
			calcPos.should.be.a('function')

		# Keep in mind in the below that the input positionId is offset by 1 as the game state
		# position id counts 0 as small blind. The rotate function below achieves this.
		rotate = (n, i) -> (i + 1) % n

		it 'calculates correct positioning', ->
			# In heads-up you only have the button and the big blind.
			calcPos(2, rotate(2, pos.button)).should.equal(pos.button)
			calcPos(2, rotate(2, pos.sb)).should.equal(pos.bb)

		it 'calculates correct positioning for 3 players', ->
			for p, i in [ pos.sb, pos.bb, pos.button ]
				calcPos(3, i).should.equal(p)

		it 'calculates correct positioning for 4 players', ->
			for p, i in [ pos.sb, pos.bb, pos.utg, pos.button ]
				calcPos(4, i).should.equal(p)

		it 'calculates correct positioning for 5 players', ->
			for p, i in [ pos.sb, pos.bb, pos.utg, pos.co, pos.button ]
				calcPos(5, i).should.equal(p)

		it 'calculates correct positioning for 6 players', ->
			for p, i in [ pos.sb, pos.bb, pos.utg, pos.hj, pos.co, pos.button ]
				calcPos(6, i).should.equal(p)

		it 'calculates correct positioning for 7 players', ->
			for p, i in [ pos.sb, pos.bb, pos.utg, pos.mp1, pos.hj, pos.co, pos.button ]
				calcPos(7, i).should.equal(p)

		it 'calculates correct positioning for 8-12 players', ->
			table = [ pos.sb, pos.bb, pos.utg, pos.mp1, pos.mp, pos.hj, pos.co, pos.button ]
			for n in [8..12]
				calcPos(n, i).should.equal(p) for p, i in table
				table.splice(4, 0, pos.mp)

	describe 'classifyHand', ->
		charlie = new Charlie()
		charlie.classifyHand.should.be.a('function')
		classifyHand = charlie.classifyHand.bind(charlie)

		typeCounts = new Uint32Array(9)

		for cardSet in combin([ 0...52 ], 5)
			vals = _.map(cardSet, (c) -> 2 + (c % 13))
			suits = _.map(cardSet, (c) -> allSuits[Math.floor(c / 13)]).join('')

			classified = classifyHand(suits, vals)
			typeCounts[classified.type]++

		{ pokerHand } = charlie

		# Using counts from http://en.wikipedia.org/wiki/Poker_hands.

		it 'should detect the correct number of straight flushes', ->
			typeCounts[pokerHand.straightFlush].should.equal(40)

		it 'should detect the correct number of 4-of-a-kinds', ->
			typeCounts[pokerHand.fourKind].should.equal(624)

		it 'should detect the correct number of full houses', ->
			typeCounts[pokerHand.fullHouse].should.equal(3744)

		it 'should detect the correct number of flushes', ->
			typeCounts[pokerHand.flush].should.equal(5108)

		it 'should detect the correct number of straights', ->
			typeCounts[pokerHand.straight].should.equal(10200)

		it 'should detect the correct number of 3-of-a-kinds', ->
			typeCounts[pokerHand.threeKind].should.equal(54912)

		it 'should detect the correct number of 2 pairs', ->
			typeCounts[pokerHand.twoPair].should.equal(123552)

		it 'should detect the correct number of pairs', ->
			typeCounts[pokerHand.pair].should.equal(1098240)

		it 'should detect the correct number of high cards', ->
			typeCounts[pokerHand.highCard].should.equal(1302540)

		it "shouldn't detect a straight flush with a different straight and a different flush.", ->
			classified = classifyHand('dddsdd', [ 7, 8, 9, 10, 11, 4 ])
			classified.type.should.equal(pokerHand.flush)

		it "shouldn't detect a straight flush with a different straight and a different flush containing the wheel.", ->
			classified = classifyHand('dddsddc', [ 2, 3, 4, 5, 14, 9, 2 ])
			classified.type.should.equal(pokerHand.flush)

		it 'should correctly return the high card value', ->
			for i in [ 0...TEST_COUNT ]
				vals = _.sample([ 2...14 ], _.random(5, 7))

				if charlie.containsStraight(vals)
					i--
					continue

				classified = classifyHand('cshdc', vals)
				classified.type.should.equal(pokerHand.highCard)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)
				classified.vals[0].should.equal(charlie.maxArr(vals))

		it 'should correctly return the pair value', ->
			for i in [ 0...TEST_COUNT ]
				cardCount = _.random(5, 7)

				vals = _.sample([ 2...14 ], cardCount)
				pairVal = vals[1] = vals[0]

				if charlie.containsStraight(vals)
					i--
					continue

				classified = classifyHand('cshdcsh'[ 0...cardCount ], vals)
				classified.type.should.equal(pokerHand.pair)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)

				classified.vals[0].should.equal(pairVal)

		it 'should correctly return the 2-pair values', ->
			for i in [ 0...TEST_COUNT ]
				cardCount = _.random(5, 7)

				vals = _.sample([ 2...14 ], cardCount)
				max = vals[1] = vals[0]
				min = vals[3] = vals[2]

				[ min, max ] = [ max, min ] if max < min

				vals = _.shuffle(vals)

				if charlie.containsStraight(vals)
					i--
					continue

				classified = classifyHand('cshdcsh'[ 0...cardCount ], vals)
				classified.type.should.equal(pokerHand.twoPair)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(2)

				classified.vals.should.eql([ max, min ])

		it 'should correctly return the 3-of-a-kind value', ->
			for i in [ 0...TEST_COUNT ]
				cardCount = _.random(5, 7)

				vals = _.sample([ 2...14 ], cardCount)
				kindVal = vals[0] = vals[1] = vals[2]
				vals = _.shuffle(vals)

				if charlie.containsStraight(vals)
					i--
					continue

				classified = classifyHand('cshdcsh'[ 0...cardCount ], vals)
				classified.type.should.equal(pokerHand.threeKind)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)

				classified.vals[0].should.equal(kindVal)

		it 'should correctly return the straight value', ->
			for i in [ 0...TEST_COUNT ]
				straight = _.random(5, 14)

				if straight == 5
					vals = [ 2..5 ].concat(14)
				else
					vals = [ straight..straight - 4 ]

				vals = _.shuffle(vals)

				classified = classifyHand('cshdc', vals)
				classified.type.should.equal(pokerHand.straight)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)

				classified.vals[0].should.equal(straight)

		it 'should correctly return the flush value', ->
			for i in [ 0...TEST_COUNT ]
				cardCount = _.random(5, 7)

				vals = _.sample([ 2...14 ], cardCount)

				if charlie.containsStraight(vals)
					i--
					continue

				suit = _.sample(allSuits)
				suits = repeat(suit, cardCount)

				maxVal = charlie.maxArr(vals)

				classified = classifyHand(suits, vals)
				classified.type.should.equal(pokerHand.flush)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)

				classified.vals[0].should.equal(maxVal)

		it 'should correctly return the full house values', ->
			for i in [ 0...TEST_COUNT ]
				cardCount = _.random(5, 7)

				vals = _.sample([ 2...14 ], cardCount)
				over = vals[2] = vals[1] = vals[0]
				under = vals[4] = vals[3]

				vals = _.shuffle(vals)

				classified = classifyHand('cshdcsh'[ 0...cardCount ], vals)
				classified.type.should.equal(pokerHand.fullHouse)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(2)

				classified.vals.should.eql([ over, under ])

		it 'should correctly return the 4-of-a-kind value', ->
			for i in [ 0...TEST_COUNT ]
				cardCount = _.random(5, 7)

				vals = _.sample([ 2...14 ], cardCount)
				kindVal = vals[0] = vals[1] = vals[2] = vals[3]
				vals = _.shuffle(vals)

				classified = classifyHand('cshdcsh'[ 0...cardCount ], vals)
				classified.type.should.equal(pokerHand.fourKind)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)

				classified.vals[0].should.equal(kindVal)

		it 'should correctly return the straight flush value', ->
			for i in [ 0...TEST_COUNT ]
				straight = _.random(5, 14)

				if straight == 5
					vals = [ 2..5 ].concat(14)
				else
					vals = [ straight..straight - 4 ]

				vals = _.shuffle(vals)

				suit = _.sample(allSuits)
				suits = repeat(suit, 5)

				classified = classifyHand(suits, vals)
				classified.type.should.equal(pokerHand.straightFlush)
				classified.vals.should.be.an('array')
				classified.vals.should.be.length(1)

				classified.vals[0].should.equal(straight)

	describe 'containsFlush', ->
		charlie = new Charlie()

		it 'detects a flush in 5-7 cards', ->
			for f in allSuits
				suits = [ f, f, f, f, f ]

				charlie.containsFlush(suits).should.equal(f)

				for o1 in allSuits
					for o2 in allSuits
						for i in [0...6]
							suits.splice(i, 0, o1)

							charlie.containsFlush(suits).should.equal(f)

							suits.splice(i, 1)

							for j in [0...7]
								suits.splice(j, 0, o2)

								charlie.containsFlush(suits).should.equal(f)

								suits.splice(j, 1)

		it "doesn't detect flushes in 1-4 cards", ->
			for n in [1..4]
				for suits in permute(allSuits, n, true)
					charlie.containsFlush(suits).should.equal(false)

		it "doesn't detect flushes in 5-7 cards with < 5 of same suit", ->
			for n in [5..7]
				for suits in permute(allSuits, n, true)
					counts = _.countBy(suits, (s) -> s)
					continue if n >= 5 for s, n of counts

					charlie.containsFlush(suits).should.be.false

	describe 'containsNofaKind', ->
		charlie = new Charlie()

		charlie.containsNofaKind.should.be.a('function')
		containsNofaKind = charlie.containsNofaKind.bind(charlie)

		it 'should not find any matches when no values duplicated', ->
			for vals in permute([ 2..14 ], 5)
				addExtra(vals, true)
				containsNofaKind(vals).should.be.false

		# Helper function to assert that the containsNofaKind function finds all of the input
		# array's 'N-of-kinds', e.g. findsNofaKind([ 2, 3 ]) finds all full houses.
		findsNofaKind = (counts) ->
			# We only need to permute sum(c - 1 for each c in counts).
			permuteCount = _.reduce(counts, ((s, c) -> s - c + 1), 5)

			for vals in permute([ 2..14 ], permuteCount)
				addExtra(vals, true)

				pairVals = _.sample(vals, counts.length)

				expected =
					valToCount: {}
					countToVals: {}

				for count, i in counts
					pairVal = pairVals[i]
					expected.valToCount[pairVal] = count

					countToVals = expected.countToVals[count]

					if !countToVals?
						expected.countToVals[count] = countToVals = []

					countToVals.push(pairVal)

					for j in [ 0...count - 1 ]
						index = _.random(vals.length)

						vals.splice(index, 0, pairVal)

				for count, expectedVals of expected.countToVals
					charlie.sortNum(expectedVals)

				containsNofaKind(vals).should.eql(expected)

		it 'should find pairs', -> findsNofaKind([ 2 ])
		it 'should find 2 pairs', -> findsNofaKind([ 2, 2 ])
		it 'should find 3-of-a-kinds', -> findsNofaKind([ 3 ])
		it 'should find 4-of-a-kinds', -> findsNofaKind([ 4 ])
		it 'should find full houses', -> findsNofaKind([ 2, 3 ])

	describe 'containsStraight', ->
		charlie = new Charlie()

		charlie.containsStraight.should.be.a('function')
		containsStraight = charlie.containsStraight.bind(charlie)

		it 'should not recognise a straight when there are less than 5 cards', ->
			containsStraight(_.sample([ 2..14 ], n)).should.be.false for n in [1..4]

		it 'should detect all straights correctly, include the wheel', ->
			for vals in permute([2..14], 5, true)
				# Only consider 5% of hands if quick mode is activated.
				if QUICK and Math.random() > 0.05
					continue

				# Use a counting sort.
				counts = new Uint8Array(14 + 1)

				addExtra(vals)

				invalid = false
				for val in vals
					n = ++counts[val]
					invalid = true if n > 4

				# Ignore invalid hands.
				continue if invalid

				straight = false
				max = -1

				streak = 0
				for count, val in counts
					if count == 0
						streak = 0
					else
						streak++
						max = val if val > max

					isWheel = val == 5 and streak == 4 and counts[14] > 0
					if streak == 5 or isWheel
						straight = true
						break

				if straight
					containsStraight(vals).should.equal(max)
				else
					containsStraight(vals).should.be.false

	describe 'inRange', ->
		charlie = new Charlie()
		charlie.inRange.should.be.a('function')
		inRange = charlie.inRange.bind(charlie)

		it 'detects correct ranges for each possible face combination + suited/unsuited', ->
			_.each allFaces, (face1, i) ->
				_.each allFaces[i...], (face2) ->
					range = "#{face1}#{face2}"
					rangePair = range[0] == range[1]
					_.each allHands, (hand) ->
						# Only consider 5% of hands if quick mode is activated.
						return if QUICK and Math.random() > 0.05

						setCharlie(charlie, hand)
						{ faces, pair, suits } = charlie.state

						actualVal1 = charlie.handVals[faces[0]]
						expectedVal1 = charlie.handVals[face1]

						actualVal2 = charlie.handVals[faces[1]]
						expectedVal2 = charlie.handVals[face2]

						expected =
							if rangePair
								pair and actualVal1 >= expectedVal1
							else
								actualVal1 >= expectedVal1 and actualVal2 >= expectedVal2

						inRange(range).should.equal(expected)
						# Test with the '+' suffix as well. This should make no difference.
						inRange(range + '+').should.equal(expected)

						# Test suited ranges - if a pair can't be suited.
						if !rangePair
							# TODO: Bring suited into Charlie.
							suited = suits[0] == suits[1]
							expectedSuited = expected and !pair and suited

							inRange(range + 's').should.equal(expectedSuited)

	describe 'getBigBlind', ->
		it 'should return the biggest blind any player possesses.', ->
			players = [
				blind: 50
			,
				blind: 0
			,
				blind: -10
			,
				blind: 15
			,
				blind: 35
			]

			Charlie::getBigBlind(players).should.equal(50)

	describe 'preflopBet', ->
		it 'goes all-in with a monster hand', ->
			charlie = new Charlie()
			charlie.state.chips = 100
			charlie.state.monster = true

			# Playability should make no difference.
			charlie.state.playable = true
			charlie.preflopBet().should.equal(100)
			charlie.state.playable = false
			charlie.preflopBet().should.equal(100)

		it 'plays 4*minimum raise with a playable hand and first betting round', ->
			charlie = new Charlie()

			charlie.state.bettingRound = 1

			charlie.state.betting = raise: 15
			charlie.state.playable = true

			charlie.preflopBet().should.equal(60)

		it 'calls with a playable hand after first betting round', ->
			charlie = new Charlie()

			charlie.state.bettingRound = 2

			charlie.state.betting = call: 17
			charlie.state.playable = true

			charlie.preflopBet().should.equal(17)

		it 'check/folds if neither playable nor monster', ->
			charlie = new Charlie()
			charlie.preflopBet().should.equal(charlie.specialBet.checkFold)

	describe 'postflopBet', ->
		it 'plays 4*minimum raise if hand is playable and first betting round', ->
			charlie = new Charlie()
			charlie.state.betting = raise: 7

			charlie.state.bettingRound = 1
			charlie.state.playable = true

			charlie.postflopBet().should.equal(28)

		it 'calls with a playable hand after first betting round', ->
			charlie = new Charlie()

			charlie.state.bettingRound = 2

			charlie.state.betting = call: 17
			charlie.state.playable = true

			charlie.postflopBet().should.equal(17)

		it 'check/folds if not playable', ->
			charlie = new Charlie()
			charlie.state.bb = 7

			charlie.state.playable = false
			charlie.postflopBet().should.equal(charlie.specialBet.checkFold)

	describe 'sortNum', ->
		ns = [ 10, 3, 1, 100, 11 ]
		sorted = [ 1, 3, 10, 11, 100 ]

		it 'sorts an array numerically.', ->
			Charlie::sortNum(ns).should.eql(sorted)
