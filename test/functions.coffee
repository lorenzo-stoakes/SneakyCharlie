_ = require('lodash')
fs = require('fs')
require('chai').should()

Charlie = require('../src/challengerBot')

# Use example game data from JsPoker README.
gameData = JSON.parse(fs.readFileSync(__dirname + '/GameData.json'))

# If ALL_TESTS not set run a subset in sane time, otherwise it takes several seconds.
QUICK = !process.env.ALL_TESTS

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

describe "Charlie's function", ->
	describe 'analyse', ->
		charlie = new Charlie()
		analyse = charlie.analyse.bind(charlie)

		sortNumArgs = null
		calcPosArgs = null
		getBigBlindArgs = null

		# Stub out some functions.
		charlie.sortNum = ->
			sortNumArgs = argsToArray(arguments)

		charlie.calcPos = ->
			calcPosArgs = argsToArray(arguments)

			return charlie.pos.co

		charlie.getBigBlind = ->
			getBigBlindArgs = argsToArray(arguments)

			return 17

		it 'is a function', ->
			analyse.should.be.a('function')

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

		it 'should have called sortNum with expected inputs', ->
			sortNumArgs.should.eql([ [ 4, 11 ] ])

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

	describe 'containsFlush', ->
		charlie = new Charlie()

		# Detects flushes in 5, 6, and 7 card hands.
		do ->
			for f in allSuits
				suits = [ f, f, f, f, f ]

				it "detects a #{f} flush in 5 cards", ->
					charlie.containsFlush(suits).should.equal(f)

				for o1 in allSuits
					for o2 in allSuits
						for i in [0...6]
							suits.splice(i, 0, o1)

							it "detects a #{f} flush in 6 cards", ->
								charlie.containsFlush(suits).should.equal(f)

							suits.splice(i, 1)

							for j in [0...7]
								suits.splice(j, 0, o2)

								it "detects a #{f} flush in 7 cards", ->
									charlie.containsFlush(suits).should.equal(f)

								suits.splice(j, 1)

		do ->
			for n in [1..4]
				for suits in permute(allSuits, n, true)
					it "doesn't detect flushes in 1-4 cards", ->
						charlie.containsFlush(suits).should.equal(false)

		do ->
			for n in [5..7]
				for suits in permute(allSuits, n, true)
					counts = _.countBy(suits, (s) -> s)
					continue if n >= 5 for s, n of counts

					it "doesn't detect flushes in 5-7 cards with < 5 of same suit", ->
						charlie.containsFlush(suits).should.be.false
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

				# Use a counting sort -
				counts = new Uint8Array(14 + 1)

				# To avoid running excessive numbers of test cases, randomly add extra cards so we
				# check 5,6,7-card hands 1/3 of the time each.
				extras = _.random(0, 2)
				for i in [0...extras]
					vals.push(_.random(2, 14))

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

		_.each allFaces, (face1, i) ->
			_.each allFaces[i...], (face2) ->
				range = "#{face1}#{face2}"
				rangePair = range[0] == range[1]
				_.each allHands, (hand) ->
					# Only consider 5% of hands if quick mode is activated.
					return if QUICK and Math.random() > 0.05

					it "detects correctly for range #{range} and hand #{hand}", ->
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

						if !rangePair
							it 'suited', ->
								# TODO: Bring suited into Charlie.
								suited = suits[0] == suits[1]
								expected = expected and !pair and suited

								inRange(range + 's').should.equal(expected)

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

		it 'plays 4*minimum raise with a playable hand', ->
			charlie = new Charlie()
			charlie.state.betting = raise: 15
			charlie.state.playable = true

			charlie.preflopBet().should.equal(60)

		it 'check/folds if neither playable nor monster', ->
			charlie = new Charlie()
			charlie.preflopBet().should.equal(charlie.specialBet.checkFold)

	describe 'postflopBet', ->
		charlie = new Charlie()

		charlie.state.bb = 7

		it 'plays 4*BB if hand is playable', ->
			charlie.state.playable = true
			charlie.postflopBet().should.equal(28)

		it 'check/folds if not playable', ->
			charlie.state.playable = false
			charlie.postflopBet().should.equal(charlie.specialBet.checkFold)

	describe 'sortNum', ->
		ns = [ 10, 3, 1, 100, 11 ]
		sorted = [ 1, 3, 10, 11, 100 ]

		it 'sorts an array numerically.', ->
			Charlie::sortNum(ns).should.eql(sorted)
