########################################################################################
### Modules
########################################################################################

stream = require 'stream'
util = require 'util'

logger = require '../log/logger'



########################################################################################
### Stream
########################################################################################

BokehTaskSubmitterStream = (client, taskQueue, options) ->
	options or options = {}

	writeOptions =
		objectMode: true

	if options.highWaterMark
		writeOptions.highWaterMark = options.highWaterMark

	stream.Writable.call(this, writeOptions)
	@client = client
	@taskQueue = taskQueue

util.inherits(BokehTaskSubmitterStream, stream.Writable)

BokehTaskSubmitterStream.prototype._write = (records, encoding, cb) ->
	@client.submitTask @taskQueue, records, cb



########################################################################################
### Exports
########################################################################################

module.exports = BokehTaskSubmitterStream
