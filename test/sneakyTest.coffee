_ = require('lodash')
require('chai').should()

makeSneaky = require '../src/challengerBot'

sneaky = makeSneaky()

describe 'sortNum', ->
	ns = [ 10, 3, 1, 100, 11 ]
	sorted = [ 1, 3, 10, 11, 100 ]

	it 'Sorts an array numerically.', ->
		sneaky.sortNum(ns).should.eql(sorted)

