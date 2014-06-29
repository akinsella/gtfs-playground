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

	@model = options.model
	@agency = options.agency
	@amqpClient = amqp.createClient("TASK_SUBMITTER")
	@taskQueue = taskQueue

util.inherits(AmqpTaskSubmitterStream, stream.Writable)

AmqpTaskSubmitterStream.prototype._write = (records, encoding, cb) ->

	records = records.reduce (previousValue, currentValue, index, array) ->
		previousValue + currentValue + '\n'
	, ''

#	logger.info "Creating Buffer for string with length: #{records.length}"

	buffer = new Buffer(records.length)
	buffer.write(records)

	@amqpClient.publishText "#{@agency.key}.#{@model}", records, cb


########################################################################################
### Exports
########################################################################################

module.exports = AmqpTaskSubmitterStream
