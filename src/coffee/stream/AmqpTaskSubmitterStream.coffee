########################################################################################
### Modules
########################################################################################

stream = require 'stream'
util = require 'util'

logger = require '../log/logger'

amqp = require '../lib/amqp'


########################################################################################
### Stream
########################################################################################

AmqpTaskSubmitterStream = (taskQueue, options) ->
	options or options = {}

	writeOptions =
		objectMode: true

	if options.highWaterMark
		writeOptions.highWaterMark = options.highWaterMark

	stream.Writable.call(this, writeOptions)

	@amqpClient = amqp.createClient("TASK_SUBMITTER")
	@taskQueue = taskQueue

util.inherits(AmqpTaskSubmitterStream, stream.Writable)

AmqpTaskSubmitterStream.prototype._write = (records, encoding, cb) ->
	@amqpClient.publishJSON @taskQueue, records, cb


########################################################################################
### Exports
########################################################################################

module.exports = AmqpTaskSubmitterStream
