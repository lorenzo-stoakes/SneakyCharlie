_ = require('lodash')
require('chai').should()

Charlie = require('../src/challengerBot')
charlie = new Charlie()

# Helper function to generate object mapping from array entries to index values.
arrayToReverseObj = (arr) ->
	ret = {}

	for val, i in arr
		ret[val] = i

	return ret

describe "Charlie's instance variables", ->
	positions = [
		'button'
		'sb'
		'bb'
		'utg'
		'mp1'
		'mp'
		'hj'
		'co'
	]

	describe 'handVals', ->
		it 'should map to expected values', ->
			charlie.handVals.should.eql
				2: 2
				3: 3
				4: 4
				5: 5
				6: 6
				7: 7
				8: 8
				9: 9
				T: 10
				J: 11
				Q: 12
				K: 13
				A: 14

	describe 'info', ->
		it 'should be an object', ->
			charlie.info.should.be.an('object')

		it 'should specify name, email and btcWallet only', ->
			charlie.info.should.have.keys([ 'name', 'email', 'btcWallet' ])

	describe 'pokerHand', ->
		{ pokerHand } = charlie

		keys = [
			'highCard'
			'pair'
			'twoPair'
			'threeKind'
			'straight'
			'flush'
			'fullHouse'
			'fourKind'
			'straightFlush'
		]

		it 'should be an object', ->
			pokerHand.should.be.an('object')

		it 'should have expected keys', ->
			pokerHand.should.have.keys(keys)

		it 'should have indexes in the expected order', ->
			pokerHand.should.eql(arrayToReverseObj(keys))

	describe 'pos', ->
		{ pos } = charlie

		it 'should have keys consisting only of all positions', ->
			pos.should.have.keys(positions)

		it 'should have indexes in the expected order', ->
			pos.should.eql(arrayToReverseObj(positions))

	describe 'posNames', ->
		it 'should match expected values', ->
			charlie.posNames.should.eql(positions)

	describe 'preflopRanges', ->
		{ preflopRanges } = charlie

		it 'should be an array', ->
			preflopRanges.should.be.an('array')

		it 'should have values for each position', ->
			preflopRanges.should.have.length.of(positions.length)

		_.each preflopRanges, (rangeSet, i) ->
			describe "range set #{i}", ->
				it 'should be an array', ->
					rangeSet.should.be.an('array')

				_.each rangeSet, (range, j) ->
					describe "range #{j}", ->
						it 'should be a string', ->
							range.should.be.a('string')

						it 'should start with face characters', ->
							range.should.match(/^[2-9TJQKA]{2}/)

						it 'should end with face characters or s, +', ->
							range.should.match(/[2-9TJQKAs+]+$/)

	describe 'specialBet', ->
		it 'should contain fold and checkFold keys', ->
			charlie.specialBet.should.contain.keys([ 'fold', 'checkFold' ])

	# TODO: Update game state and re-check.
	describe 'state', ->
		{ state } = charlie

		it 'should contain only expected keys', ->
			state.should.have.keys [
				'betting'
				'bb'
				'chips'
				'community'
				'communitySuits'
				'communityVals'
				'faces'
				'hand'
				'monster'
				'pair'
				'playable'
				'pos'
				'suits'
				'vals'
			]

		{ vals } = state

		it 'should have keys of expected type', ->
			(state.betting ? {}).should.be.an('object')
			(state.bb ? 0).should.be.a('number')
			(state.chips ? 0).should.be.a('number')
			(state.community ? '').should.be.a('string')
			(state.communitySuits ? '').should.be.a('string')
			(state.communityVals ? []).should.be.an('array')
			(state.faces ? '').should.be.a('string')
			(state.hand ? '').should.be.a('string')
			(state.monster ? false).should.be.a('boolean')
			(state.pair ? false).should.be.a('boolean')
			(state.playable ? false).should.be.a('boolean')
			(state.pos ? 0).should.be.a('number')
			(state.suits ? '').should.be.a('string')
			vals.should.be.an('array')

		describe 'vals', ->
			it 'should be of length 2', ->
				vals.should.be.of.length(2)

			_.each vals, (val, i) ->
				describe "val #{i}", ->
					it 'should be a number', ->
						val.should.be.a('number')
