module.exports = class
	constructor: ->
		@pos[p] = i for p, i in @posNames

		# Assign 2-9.
		# Don't need to make ints strings, but feels nicer to be explicit here.
		@handVals['' + i] = i for i in [2..9]

	bet:
		fold: -1  # Negative value means fold.
		checkFold: 0

	handVals: { T: 10, J: 11, Q: 12, K: 13, A: 14 }

	info:
		# We gotta be sneaky Charlie! Sneaky!
		# http://www.youtube.com/watch?v=29xJRc329eI
		name: 'SneakyCharlie'
		email: 'lstoakes@gmail.com'
		btcWallet: '1EyBrQTnHGiKNwqFcSBn9Ua4KX1t8gQjet'

	posNames: [ 'button', 'sb', 'bb', 'utg', 'mp1', 'mp', 'hj', 'co' ]

	# A poor mans enum.
	pos: {}

	# Map to positions.
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

	# We keep track of game state here.
	state: {}

	# Functions

	# Determine some useful info about the game.
	analyse: (game) ->
		{ betting, self: { cards, chips, position }, players, state: round } = game

		# Easier to play with the hand as a string e.g. 'AcAs'
		hand = cards.sort().join('')
		# Convenient strings consisting only of values + suits.
		faces = hand[0] + hand[2]
		suits = hand[1] + hand[3]

		@state.faces = faces
		@state.hand = hand
		@state.suits = suits

		# Numerical values of faces.
		@state.vals = [ @handVals[faces[0]], @handVals[faces[1]] ]
		@sortNum(@state.vals)

		@state.pos = currPos = @calcPos(players.length, position)

		@state.bb = @getBigBlind(players)

		if round == 'pre-flop'
			@state.playable = false
			for range in @preflopRanges[currPos] when @inRange(hand, range, suits, @state.vals)
				@state.playable = true
				break
		else
			@state.playable = true

		# Do we have a monster hand?
		@state.monster = @state.faces in [ 'AA', 'KK' ]
		# Do we have a pair?
		@state.pair = @state.faces[0] == @state.faces[1]

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

	# Check whether a given hand is in the specified range.
	inRange: (hand, range, suits, actualVals) ->
		# We don't care about the + suffix as it is decorative and implied. Only an 's' suffix
		# vs. 'o' or missing suffix is meaningful.
		suited = 's' in range[2...]
		return false if suited and suits[0] != suits[1]

		# Expected numerical vals from range.
		expectedVals = (@handVals[r] for r in range[...2])
		@sortNum(expectedVals)

		pair = range[0] == range[1]
		if pair
			actual = actualVals[0]
			# Abort if input hand is not a pair.
			return false if actual != actualVals[1]
			# Value of expected pair.
			expected = expectedVals[0]
			return actual >= expected

		# Otherwise we simply need to check that we have a hand greater than or equal to
		# expectation.

		return actualVals[0] >= expectedVals[0] and actualVals[1] >= expectedVals[1]

	getBigBlind: (players) ->
		ret = 0
		ret = p.blind for p in players when p.blind > ret
		return ret

	preflopBet: ->
		switch
			# All-in if we have AA, KK.
			when @state.monster then @state.chips
			# If other pair, 4*BB.
			when @state.playable then 4 * @state.betting.raise
			# Otherwise, we have to be careful Charlie! Throw that 72o away!
			else @bet.checkFold

	postflopBet: ->
		if @state.playable
			4 * @state.bb
		else
			@bet.checkFold
	sortNum: (ns) ->
		ns.sort((a,b) -> a - b)

	update: (game) ->
		@analyse(game)

		switch @state.round
			when 'complete' then null
			when 'pre-flop' then @preflopBet()
			else @postflopBet()
