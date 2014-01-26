# A class representing the Sneaky Charlie JsPoker bot. As per the rules, all functionality is
# kept in a single module.
module.exports = class
	## Ctor

	constructor: ->
		# Assign position 'enum'.
		@pos[p] = i for p, i in @posNames

		# Assign 2-9.
		# Don't need to make ints strings, but feels nicer to be explicit here.
		@handVals['' + i] = i for i in [2..9]

	## Instance Vars

	# Bet values that have meaning other than their numerical value.
	specialBet:
		fold: -1  # Negative value means fold.
		checkFold: 0 # Check if possible, fold otherwise.

	# Numerical values of each face value. 2-9 are assigned in ctor.
	handVals: { T: 10, J: 11, Q: 12, K: 13, A: 14 }

	# Tell the world who we are.
	info:
		# We gotta be sneaky Charlie! Sneaky!
		# http://www.youtube.com/watch?v=29xJRc329eI
		name: 'SneakyCharlie'
		email: 'lstoakes@gmail.com'
		btcWallet: '1EyBrQTnHGiKNwqFcSBn9Ua4KX1t8gQjet'

	# Names of each position around the table. The assignment of these varies depending on
	# the number of players, see calcPos() for details on how this is assigned.
	posNames: [ 'button', 'sb', 'bb', 'utg', 'mp1', 'mp', 'hj', 'co' ]

	# A poor mans enum, assigned in ctor mapping position names to index positions in
	# @posNames.
	pos: {}

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

	# Convenient representation of game state. Generated from provided game var on update.
	state:
		bb: null         # Current big blind.
		faces: null      # Faces string e.g. AA.
		hand: null       # Hand string e.g. AcAs.
		monster: false   # Is this hand a complete monster?
		pair: false      # Is this hand a pair?
		playable: false  # Is the hand playable?
		pos: null        # Current position, index of posNames.
		suits: null      # Suits string e.g. cs.
		vals: [ 0, 0 ]   # Sorted numerical face value of cards in hand.

	## Functions

	# Determine some useful info about the game, assign to @state.
	analyse: (game) ->
		{ betting, self: { cards, chips, position }, players, state: round } = game

		# Easier to play with the hand as a string e.g. 'AcAs'
		@state.hand = hand = cards.sort().join('')
		# Convenient strings consisting only of values + suits.
		@state.faces = faces = hand[0] + hand[2]
		@state.suits = suits = hand[1] + hand[3]

		# Numerical values of faces.
		@state.vals = [ @handVals[faces[0]], @handVals[faces[1]] ]
		@sortNum(@state.vals)

		@state.pos = currPos = @calcPos(players.length, position)

		@state.bb = @getBigBlind(players)

		if round == 'pre-flop'
			@state.playable = false
			for range in @preflopRanges[currPos] when @inRange(range)
				@state.playable = true
				break
		else
			@state.playable = true

		# Do we have a monster hand?
		@state.monster = faces in [ 'AA', 'KK' ]
		# Do we have a pair?
		@state.pair = faces[0] == faces[1]

	# Calculate a more useful representation of position.
	calcPos: (playerCount, positionId) ->
		# 0 == sb so adjust such that 0 = button.
		positionId++
		positionId %= playerCount

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

	# Check whether the current hand is in the specified range.
	inRange: (range) ->
		{ suits, vals } = @state

		# We don't care about the + suffix as it is decorative and implied. Only an 's' suffix
		# vs. 'o' or missing suffix is meaningful.
		suited = 's' in range[2...]
		return false if suited and suits[0] != suits[1]

		# Expected numerical vals from range.
		expectedVals = (@handVals[r] for r in range[...2])
		@sortNum(expectedVals)

		pair = range[0] == range[1]
		if pair
			actual = vals[0]
			# Abort if input hand is not a pair.
			return false if actual != vals[1]
			# Value of expected pair.
			expected = expectedVals[0]
			return actual >= expected

		# Otherwise we simply need to check that we have a hand greater than or equal to
		# expectation.

		return vals[0] >= expectedVals[0] and vals[1] >= expectedVals[1]

	# Determine what the big blind is.
	# TODO: Necessary/useful?
	getBigBlind: (players) ->
		ret = 0
		ret = p.blind for p in players when p.blind > ret
		return ret

	# Given the current state of the game, how much should we bet preflop?
	preflopBet: ->
		switch
			# All-in if we have AA, KK.
			when @state.monster then @state.chips
			# If other pair, 4*BB.
			when @state.playable then 4 * @state.betting.raise
			# Otherwise, we have to be careful Charlie! Throw that 72o away!
			else @specialBet.checkFold

	# Given the current state of the game, how much should we bet postflop?
	postflopBet: ->
		if @state.playable
			4 * @state.bb
		else
			@specialBet.checkFold

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
