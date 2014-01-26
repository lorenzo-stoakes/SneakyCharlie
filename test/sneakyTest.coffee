_ = require('lodash')
require('chai').should()

makeSneaky = require '../src/challengerBot'

sneaky = makeSneaky()

describe 'sortNum', ->
	ns = [ 10, 3, 1, 100, 11 ]
	sorted = [ 1, 3, 10, 11, 100 ]

	it 'Sorts an array numerically.', ->
		sneaky.sortNum(ns).should.eql(sorted)

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
		sneaky.pos.should.have.keys(positions)

	# Convert array above to obj of { arr[0]: 0, arr[1]: 1, etc. } - i.e. the expected enum.
	postEnum = _.reduce(positions, ((obj, k, v) -> obj[k] = v; obj), {})

	it 'Should have indexes in the expected order', ->
		sneaky.pos.should.eql(postEnum)
