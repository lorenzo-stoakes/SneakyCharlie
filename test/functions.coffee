require('chai').should()

Charlie = require('../src/challengerBot')
charlie = new Charlie()

describe "Charlie's functions", ->
	describe 'sortNum', ->
		ns = [ 10, 3, 1, 100, 11 ]
		sorted = [ 1, 3, 10, 11, 100 ]

		it 'sorts an array numerically.', ->
			charlie.sortNum(ns).should.eql(sorted)
