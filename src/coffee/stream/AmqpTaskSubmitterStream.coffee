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

	@firstLine = options.firstLine
	@model = options.model
	@agency = options.agency
	@amqpClient = amqp.createClient("TASK_SUBMITTER")
	@taskQueue = taskQueue

util.inherits(AmqpTaskSubmitterStream, stream.Writable)

AmqpTaskSubmitterStream.prototype._write = (records, encoding, cb) ->

	firstLine = @firstLine()
	if records && firstLine != records[0]
		records.unshift(firstLine)

	@amqpClient.publishText "#{@model}", { agency: { key: @agency.key }, records: records }, cb


########################################################################################
### Exports
########################################################################################

module.exports = AmqpTaskSubmitterStream
