########################################################################################
### Modules
########################################################################################

Stream = require 'stream'
util = require 'util'

logger = require '../log/logger'


########################################################################################
### Class
########################################################################################

class ArrayStream extends Stream.Readable
	constructor: (@array, @options) ->
		@options or @options = {}

		super(@options)

	_read: () ->
		if @array.length == 0
			@push null
		else
			@push(@array[0] + '\r\n');
			@array.shift()


########################################################################################
### Exports
########################################################################################

module.exports = ArrayStream