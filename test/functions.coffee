require('chai').should()

Charlie = require('../src/challengerBot')

describe "Charlie's function", ->
	describe 'analyse', ->
		charlie = new Charlie()

		{ analyse } = charlie

		it 'is a function', ->
			analyse.should.be.a('function')

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

	describe 'sortNum', ->
		ns = [ 10, 3, 1, 100, 11 ]
		sorted = [ 1, 3, 10, 11, 100 ]

		it 'sorts an array numerically.', ->
			Charlie::sortNum(ns).should.eql(sorted)
