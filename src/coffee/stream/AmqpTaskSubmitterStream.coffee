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

AmqpTaskSubmitterStream = (taskQueue) ->
	stream.Writable.call(this, { objectMode : true })
	@amqpClient = amqp.createClient("TASK_SUBMITTER")
	@taskQueue = taskQueue

util.inherits(AmqpTaskSubmitterStream, stream.Writable)

AmqpTaskSubmitterStream.prototype._write = (records, encoding, cb) ->
#	logger.info "AmqpTaskSubmitterStream: #{records.length}"
	@amqpClient.publishJSON @taskQueue, records, cb



########################################################################################
### Exports
########################################################################################

module.exports = AmqpTaskSubmitterStream
