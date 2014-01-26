_ = require('lodash')
require('chai').should()

Charlie = require('../src/challengerBot')
charlie = new Charlie()

describe 'charlie', ->
	describe 'variable', ->
		describe 'pos', ->
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

			it 'Should have keys consisting only of all positions', ->
				charlie.pos.should.have.keys(positions)

			# Convert array above to obj of { arr[0]: 0, arr[1]: 1, etc. } - i.e. the expected enum.
			postEnum = _.reduce(positions, ((obj, k, v) -> obj[k] = v; obj), {})

			it 'Should have indexes in the expected order', ->
				charlie.pos.should.eql(postEnum)

	describe 'function', ->
		describe 'sortNum', ->
			ns = [ 10, 3, 1, 100, 11 ]
			sorted = [ 1, 3, 10, 11, 100 ]

			it 'Sorts an array numerically.', ->
				charlie.sortNum(ns).should.eql(sorted)
