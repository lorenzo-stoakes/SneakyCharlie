info =
	# We gotta be sneaky Charlie! Sneaky!
	# http://www.youtube.com/watch?v=29xJRc329eI
	name: 'SneakyCharlie'
	email: 'lstoakes@gmail.com'
	btcWallet: '1EyBrQTnHGiKNwqFcSBn9Ua4KX1t8gQjet'

FOLD = -1 # Negative value means fold.
CHECK_FOLD = 0

# JS abominates sorting. Sort numerically.
sortNum = (ns) ->
	ns.sort((a,b) -> a - b)

# A poor mans enum.
[ BUTTON, SB, BB, UTG, MP1, MP, HJ, CO ] = [0...8]
posNames = [ 'button', 'sb', 'bb', 'utg', 'mp1', 'mp', 'hj', 'co' ]
pos = {}
stringPos = do ->
	posNames = [ 'button', 'sb', 'bb', 'utg', 'mp1', 'mp', 'hj', 'co' ]
	pos[p] = i for p, i in posNames

	(pos) -> posNames[pos]

bet =
	fold: -1  # Negative value means fold.
	checkFold: 0

handVals = { T: 10, J: 11, Q: 12, K: 13, A: 14 }
# Assign 2-9.
do ->
	# Don't need to make ints strings, but feels nicer to be explicit here.
	handVals['' + i] = i for i in [2..9]

# Maps to above positions.
preflopRanges = [
	[ 'A8s+', 'KQ',  'KJ', 'QJ', '22+' ] # button
	[ 'AQs',  'AK',  '77+' ]             # sb
	[ 'AQs',  'AK',  '77+' ]             # bb
	[ 'AQs',  'AK',  '77+' ]             # utg
	[ 'AJ+',  '55+' ]                    # mp1
	[ 'AJ+',  'KQs', '22+' ]             # mp
	[ 'AJ+',  'KQ',  'QJ', '22+' ]       # hj
	[ 'AJ+',  'KQ',  'QJ', '22+' ]       # co
]

# Check whether a given hand is in the specified range.
inRange = (hand, range, suits, actualVals) ->
	# We don't care about the + suffix as it is decorative and implied. Only an 's' suffix
	# vs. 'o' or missing suffix is meaningful.
	suited = 's' in range[2...]
	return false if suited and suits[0] != suits[1]

	# Expected numerical vals from range.
	expectedVals = (handVals[r] for r in range[...2])
	sortNum(expectedVals)

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

# Calculate a more useful representation of position.
calcPos = (playerCount, positionId) ->
	# 0 == SB so adjust such that 0 = BUTTON.
	positionId++
	positionId %= playerCount

	# When in button to utg, the position id matches the enum value.
	return positionId if positionId < 4

	# HJ or CO.
	fromEnd = playerCount - positionId - 1
	if fromEnd < 2
		return [ CO, HJ ][fromEnd]

	# All that remains is to differentiate between MP1 and MP.
	if positionId == 4
		MP1
	else
		MP

getBigBlind = (players) ->
	ret = 0
	ret = p.blind for p in players when p.blind > ret
	return ret

# Determine some useful info about the game.
analyse = (game) ->
	{ betting, self: { cards, chips, position }, players, state: round } = game

	# Easier to play with the hand as a string e.g. 'AcAs'
	hand = cards.sort().join('')
	# Convenient strings consisting only of values + suits.
	faces = hand[0] + hand[2]
	suits = hand[1] + hand[3]

	# Numerical values of faces.
	vals = [ handVals[faces[0]], handVals[faces[1]] ]
	sortNum(vals)

	currPos = calcPos(players.length, position)

	bb = getBigBlind(players)

	if round == 'pre-flop'
		playable = false
		for range in preflopRanges[currPos] when inRange(hand, range, suits, vals)
			playable = true
			break
	else
		playable = true

	# Do we have a monster hand?
	monster = faces in [ 'AA', 'KK' ]
	# Do we have a pair?
	pair = faces[0] == faces[1]

	return { bb, betting, chips, faces, hand, monster, pair, playable, pos: currPos, round, suits, vals }

preflopBet = (state) ->
	switch
		# All-in if we have AA, KK.
		when state.monster then state.chips
		# If other pair, 4*BB.
		when state.playable then 4 * state.betting.raise
		# Otherwise, we have to be careful Charlie! Throw that 72o away!
		else CHECK_FOLD

postflopBet = (state) ->
	if state.playable
		4 * state.bb
	else
		CHECK_FOLD

update = (game) ->
	state = analyse(game)

	switch state.round
		when 'complete' then null
		when 'pre-flop' then preflopBet(state)
		else postflopBet(state)

module.exports = -> { info, update }
