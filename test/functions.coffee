require('chai').should()

Charlie = require('../src/challengerBot')

describe "Charlie's function", ->
	describe 'analyse', ->
		charlie = new Charlie()

		{ analyse } = charlie

		it 'is a function', ->
			analyse.should.be.a('function')
	describe 'sortNum', ->
		ns = [ 10, 3, 1, 100, 11 ]
		sorted = [ 1, 3, 10, 11, 100 ]

		it 'sorts an array numerically.', ->
			Charlie::sortNum(ns).should.eql(sorted)
