########################################################################################
### Modules
########################################################################################

stream = require 'stream'
util = require 'util'

logger = require '../log/logger'


########################################################################################
### Stream
########################################################################################

class BokehTaskSubmitterStream extends stream.Writable

	constructor: (@client, @taskQueue, @options) ->
		@options or @options = {}

		writeOptions =
			objectMode: true

		if @options.highWaterMark
			writeOptions.highWaterMark = @options.highWaterMark

		super(writeOptions)


	_write: (records, encoding, cb) ->
		@client.submitTask @taskQueue, records, cb



########################################################################################
### Exports
########################################################################################

module.exports = BokehTaskSubmitterStream
