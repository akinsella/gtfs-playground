########################################################################################
### Modules
########################################################################################

stream = require 'stream'
util = require 'util'

logger = require '../log/logger'



########################################################################################
### Stream
########################################################################################

BokehTaskSubmitterStream = (client, taskQueue) ->
	stream.Writable.call(this, { objectMode : true })
	@client = client
	@taskQueue = taskQueue

util.inherits(BokehTaskSubmitterStream, stream.Writable)

BokehTaskSubmitterStream.prototype._write = (records, encoding, cb) ->
	@client.submitTask @taskQueue, records, (err, data) ->
		logger.info "[#{process.pid}] push.send ended"
		cb(err, data)



########################################################################################
### Exports
########################################################################################

module.exports = BokehTaskSubmitterStream
