########################################################################################
### Modules
########################################################################################

logger = require '../log/logger'


########################################################################################
### Class
########################################################################################

class InsertedResultConsumer

	constructor: () ->
		@inserted = 0
		@batchCount = 0

	handleMessage: (channel, message, callback) ->
		@inserted += message.inserted || 0
		@batchCount += 1

		logger.info "[MONGO][#{@batchCount}] Inserted lines: #{@inserted}" if @batchCount % 100 == 0

		if callback
			callback()


########################################################################################
### Exports
########################################################################################

module.exports = InsertedResultConsumer