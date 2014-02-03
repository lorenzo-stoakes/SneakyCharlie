# A class representing the Sneaky Charlie JsPoker bot. As per the rules, all functionality is
# kept in a single module.
module.exports = class
	constructor: ->
		# Assign position 'enum'.
		@pos[p] = i for p, i in @posNames

		# Assign 2-9.
		# Don't need to make ints strings, but feels nicer to be explicit here.
		@handVals['' + i] = i for i in [2..9]

		@state =
			bb: null             # Current big blind.
			betting: null        # Current betting state of game.
			bettingRound: 0      # Current *betting* round i.e. the number of raises - 1.
			chips: 0             # Number of chips Charlie currently has.
			community: null      # Community cards string, e.g. 'Ac3d5h2s'.
			communitySuits: null # Community suits string e.g. 'cdhs'.
			communityVals: null  # Sorted numerical face values of community cards.
			faces: null          # Faces string e.g. AA.
			hand: null           # Hand string e.g. AcAs.
			monster: false       # Is this hand a complete monster?
			pair: false          # Is this hand a pair?
			playable: false      # Is the hand playable?
			pokerHand: null      # What is our current poker hand?
			pokerHandComm: null  # What is the community poker hand?
			pokerVals: null      # The 'values' of our poker hand, i.e. high card(s).
			pokerValsComm: null  # The 'values' of the community poker hand.
			pos: null            # Current position, index of posNames.
			previousRound: null  # The previous round.
			round: null          # The current round e.g. pre-flop, flop, etc.
			suits: null          # Suits string e.g. cs.
			vals: [ 0, 0 ]       # Sorted numerical face value of cards in hand.

	## Instance Vars

	# Numerical values of each face value. 2-9 are assigned in ctor.
	handVals: { T: 10, J: 11, Q: 12, K: 13, A: 14 }

	# Tell the world who we are.
	info:
		# We gotta be sneaky Charlie! Sneaky!
		# http://www.youtube.com/watch?v=29xJRc329eI
		name: 'SneakyCharlie'
		email: 'lstoakes@gmail.com'
		btcWallet: '1NtpjxBCDi1uNHJHBnXkNh41foxWxFNzvn'

	# Map between poker hands and their value.
	pokerHand:
		straightFlush: 8
		fourKind:      7
		fullHouse:     6
		flush:         5
		straight:      4
		threeKind:     3
		twoPair:       2
		pair:          1
		highCard:      0

	# Poker hand names, map to pokerHands values.
	pokerHandNames: [
		'high card'
		'pair'
		'two pair'
		'three of a kind'
		'straight'
		'flush'
		'full house'
		'four of a kind'
		'straight flush'
	]

	# A poor mans enum, assigned in ctor mapping position names to index positions in
	# @posNames.
	pos: {}

	# Names of each position around the table. The assignment of these varies depending on
	# the number of players, see calcPos() for details on how this is assigned.
	posNames: [ 'button', 'sb', 'bb', 'utg', 'mp1', 'mp', 'hj', 'co' ]

	# Ranges of hands to play for each position in preflop - maps to posNames.
	preflopRanges: [
		[ 'A8s+', 'KQ',  'KJ', 'QJ', '22+' ] # button
		[ 'AQs',  'AK',  '77+' ]             # sb
		[ 'AQs',  'AK',  '77+' ]             # bb
		[ 'AQs',  'AK',  '77+' ]             # utg
		[ 'AJ+',  '55+' ]                    # mp1
		[ 'AJ+',  'KQs', '22+' ]             # mp
		[ 'AJ+',  'KQ',  'QJ', '22+' ]       # hj
		[ 'AJ+',  'KQ',  'QJ', '22+' ]       # co
	]

	# Bet values that have meaning other than their numerical value.
	specialBet:
		fold: -1  # Negative value means fold.
		checkFold: 0 # Check if possible, fold otherwise.

	# Convenient representation of game state. Generated from provided game var on
	# update. Assigned in ctor.
	state: null

	## Functions

	# Determine some useful info about the game, assign to @state.
	analyse: (game) ->
		{ betting, community, self: { cards, chips, position }, players, state: round } = game

		@state.betting = betting
		@state.community = community.sort().join('')
		@state.communitySuits = (s for s in @state.community[1...] by 2).sort().join('')
		@state.communityVals = (@handVals[v] for v in @state.community by 2)

		# Easier to play with the hand as a string e.g. 'AcAs'
		@state.hand = hand = cards.sort().join('')
		# Convenient strings consisting only of values + suits.
		@state.faces = faces = hand[0] + hand[2]
		@state.suits = suits = hand[1] + hand[3]

		@state.chips = chips

		# Numerical values of faces.
		@state.vals = [ @handVals[faces[0]], @handVals[faces[1]] ]
		@sortNum(@state.vals)

		@state.pos = currPos = @calcPos(players.length, position)

		@state.bb = @getBigBlind(players)

		@state.playable = false

		@state.previousRound = @state.round
		@state.round = round

		# If still the same round, then this is the next betting round.
		if @state.previousRound == round
			@state.bettingRound++
		else
			@state.bettingRound = 1

		# Do we have a pair in our hand?
		@state.pair = faces[0] == faces[1]

		if round == 'pre-flop'
			# Do we have a pre-flop monster hand?
			@state.monster = faces in [ 'AA', 'KK' ]

			for range in @preflopRanges[currPos] when @inRange(range)
				@state.playable = true
				break
		else
			allSuits = @state.suits.concat(@state.communitySuits)
			allVals = @state.vals.concat(@state.communityVals)

			classified = @classifyHand(allSuits, allVals)
			@state.pokerHand = classified.type
			@state.pokerVals = classified.vals

			classifiedComm = @classifyHand(@state.communitySuits, @state.communityVals)
			@state.pokerHandComm = classifiedComm.type
			@state.pokerValsComm = classifiedComm.vals

			superior = @state.pokerHand >= @pokerHand.threeKind
			superior = superior and @state.pokerHand >= @state.pokerHandComm

			# If same hand as community, check whether we're better on high card(s).
			if superior and @state.pokerHand == @state.pokerHandComm
				superior = false
				for highVal, i in @state.pokerVals when highVal > @state.pokerValsComm[i]
					superior = true
					break

			@state.playable = superior
			@state.monster = superior and @state.pokerHand >= @pokerHand.fullHouse


	# Calculate a more useful representation of position.
	calcPos: (playerCount, positionId) ->
		# 0 == sb so adjust such that 0 = button.
		positionId++
		positionId %= playerCount

		# Special case - heads up player 2 is the big blind.
		return @pos.bb if playerCount == 2 and positionId == 1

		# When in button to utg, the position id matches the enum value.
		return positionId if positionId < 4

		# HJ or CO.
		fromEnd = playerCount - positionId - 1
		if fromEnd < 2
			return [ @pos.co, @pos.hj ][fromEnd]

		# All that remains is to differentiate between MP1 and MP.
		if positionId == 4
			@pos.mp1
		else
			@pos.mp

	# Determines the poker hand type, i.e. high card, pair, etc. input suits and vals should be
	# synchronised. Returns an object with type set to the pokerhand type and vals set to the
	# high card value(s).
	classifyHand: (suits, vals) ->
		flush = @containsFlush(suits)
		straight = @containsStraight(vals)

		# Some special handling needed to avoid situations where > 5 cards have a separate
		# flush and straight.
		if flush and straight
			valid = true

			# Handle cases where there are separate straights and flushes.
			if vals.length > 5
				suitHash = {}
				suitHash[val] = suits[i] for val, i in vals
				# Handle wheel.
				suitHash[1] = suitHash[14]

				for val in [ straight...straight - 5 ] when suitHash[val] != flush
					valid = false
					break

			if valid
				return {
					type: @pokerHand.straightFlush
					vals: [ straight ]
				}

		ofKind = @containsNofaKind(vals)

		if (fours = ofKind.countToVals?[4])?
			return {
				type: @pokerHand.fourKind
				vals: fours
			}

		twos = ofKind.countToVals?[2]
		threes = ofKind.countToVals?[3]

		if twos? and threes?
			return {
				type: @pokerHand.fullHouse
				vals: [ @maxArr(threes), @maxArr(twos) ]
			}

		# Handle case where the hand has >1 3 count - it's a full house not 3-of-a-kind :-)
		if threes? and (len = threes.length) > 1
			@sortNum(threes)

			return {
				type: @pokerHand.fullHouse
				vals: [ threes[len - 1], threes[len - 2] ]
			}

		if flush
			max = -1

			for val, i in vals when suits[i] == flush and val > max
				max = val

			return {
				type: @pokerHand.flush
				vals: [ max ]
			}

		if straight
			return {
				type: @pokerHand.straight
				vals: [ straight ]
			}

		if threes?
			return {
				type: @pokerHand.threeKind
				vals: [ @maxArr(threes) ]
			}

		if twos?
			len = twos.length

			if len == 1
				return {
					type: @pokerHand.pair
					vals: twos
				}

			@sortNum(twos)

			return {
				type: @pokerHand.twoPair
				vals: [ twos[len - 1], twos[len - 2] ]
			}

		if !ofKind
			return {
				type: @pokerHand.highCard
				vals: [ @maxArr(vals) ]
			}

		# We shouldn't get here :)
		throw new Error('Invalid ofKind state.')

	# Does the specified suit string contain a flush? Returns the suit or false if no flush
	# exists.
	containsFlush: (suits) ->
		return false if suits == ''

		countsBySuit = {}

		for suit in suits
			n = countsBySuit[suit] ? 0
			countsBySuit[suit] = ++n

			return suit if n == 5

		return false

	# Does the specified face values array contain n-of-a-kind where n is between 2 and 4,
	# i.e. pair, 3-of-a-kind, 4-of-a-kind? This function returns an object mapping face values
	# to their counts (where they exceed 1), and vice-versa. This means this function detects
	# 2-pairs and full houses as well as pairs + 3-4 kinds. Returns false if no cards 'of a
	# kind' detected.
	containsNofaKind: (vals) ->
		# 14 + 1 as we want to actually address index 14.
		tmp = new Uint8Array(14 + 1)

		ret = null

		for val in vals
			count = ++tmp[val]

			if count > 1
				if !ret?
					ret =
						valToCount: {}
						countToVals: {}

				ret.valToCount[val] = count

		return false if !ret?

		for val, count of ret.valToCount
			needsSort = false

			# Object keys are always strings in js.
			val = parseInt(val, 10)

			countToVals = ret.countToVals[count]
			if !countToVals?
				ret.countToVals[count] = countToVals = []
			# Keep sorted.
			else
				needsSort = true

			countToVals.push(val)
			@sortNum(countToVals) if needsSort

		return ret

	# Does the specified face values array contain a straight? Returns the high card value or
	# false if no straight exists.
	containsStraight: (vals) ->
		# Can't have a straight if less than 5 cards.
		return false if vals.length < 5

		# Aces count as value 1 and 14.
		for val in vals when val is @handVals.A
			vals = vals.concat(1)
			break

		# TODO: Would likely be more efficient to use a counting sort (as in the test :P) -
		# O(n) vs. O(n log n) - but since the number of vals is low, this is something to
		# benchmark (constant factors could dominate.) Investigate.

		@sortNum(vals)

		hits = 1
		prev = vals[0]
		for val in vals[1...]
			if val == prev + 1
				hits++
			else if val != prev
				hits = 1

			return val if hits == 5

			prev = val

		return false

	# Determine what the big blind is.
	# TODO: Necessary/useful?
	getBigBlind: (players) ->
		ret = 0
		ret = p.blind for p in players when p.blind > ret
		return ret

	# Check whether the current hand is in the specified range.
	inRange: (range) ->
		{ pair, suits, vals } = @state

		# We don't care about the + suffix as it is decorative and implied. Only an 's' suffix
		# vs. 'o' or missing suffix is meaningful.
		rangeSuited = 's' in range[2...]

		# If pair or suits don't match, then definitely not in suited range.
		return false if rangeSuited and (pair or suits[0] != suits[1])

		# Expected numerical vals from range.
		expectedVals = (@handVals[r] for r in range[...2])
		@sortNum(expectedVals)

		rangePair = range[0] == range[1]
		if rangePair
			actual = vals[0]

			# Abort if input hand is not a pair.
			return false if actual != vals[1]
			# Value of expected pair.
			expected = expectedVals[0]
			return actual >= expected

		# Otherwise we simply need to check that we have a hand greater than or equal to
		# expectation.

		return vals[0] >= expectedVals[0] and vals[1] >= expectedVals[1]

	# Find max. value in an array.
	maxArr: (arr) ->
		Math.max.apply(null, arr)

	# Given the current state of the game, how much should we bet preflop?
	preflopBet: ->
		if @state.monster
			return @state.chips
		else if @state.playable
			if @state.bettingRound == 1
				return 8 * @state.betting.raise
			else
				return @state.betting.call

		# Otherwise, we have to be careful Charlie! Throw that 72o away!
		return @specialBet.checkFold

	# Given the current state of the game, how much should we bet postflop?
	postflopBet: ->
		if !@state.playable
			return @specialBet.checkFold

		if @state.monster
			return @state.chips

		if @state.bettingRound == 1
			8 * @state.betting.raise
		else
			@state.betting.call

	# Javascript abominates sorting, force numerical sort.
	sortNum: (ns) ->
		ns.sort((a,b) -> a - b)

	# Game has updated and we need to do something.
	update: (game) ->
		@analyse(game)

		switch @state.round
			when 'complete' then null
			when 'pre-flop' then @preflopBet()
			else @postflopBet()
