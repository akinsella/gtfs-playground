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
	@client.submitTask @taskQueue, records, cb



########################################################################################
### Exports
########################################################################################

module.exports = BokehTaskSubmitterStream
