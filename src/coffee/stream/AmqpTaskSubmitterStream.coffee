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

class AmqpTaskSubmitterStream extends stream.Writable

	constructor: (@taskQueue, @options) ->
		@options or @options = {}

		writeOptions =
			objectMode: true

		if options.highWaterMark
			writeOptions.highWaterMark = @options.highWaterMark

		super(writeOptions)

		@firstLine = options.firstLine
		@model = options.model
		@agency = options.agency
		@job = options.job
		@amqpClient = amqp.createClient("TASK_SUBMITTER")

	_write: (records, encoding, cb) ->

		firstLine = @firstLine()
		if records && firstLine != records[0]
			records.unshift(firstLine)

		queueName = "#{@model}_#{@job.uuid}".toUpperCase().replace /[-]/g, '_'
		@amqpClient.publishText queueName, { agency: { key: @agency.key }, records: records, job: @job }, cb


########################################################################################
### Exports
########################################################################################

module.exports = AmqpTaskSubmitterStream
