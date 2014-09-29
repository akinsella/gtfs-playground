########################################################################################
### Modules
########################################################################################

util = require 'util'
Promise = require 'bluebird'

logger = require '../log/logger'
amqp = require '../lib/amqp'


########################################################################################
### Class
########################################################################################

class JobInactivityTimeoutError extends Error

	constructor: (@agency) ->


class InsertedResultConsumer

	constructor: (@agency, @GTFSFile, @timeout) ->

		logger.info "[INSERT_RESULT_CONSUMER][START] Starting Insert Result Consumer for agency: '#{@agency.key}' and GTFS File: '#{@GTFSFile.fileNameBase}'"

		self = this
		@inserted = 0
		@errors = 0
		@batchResultCount = 0
		@previousBatchResultCount = 0
		@batchResultCountExpected = undefined

		@deferred = Promise.pending()

		intervalRef = setInterval () =>
			if self.previousBatchResultCount == self.batchResultCount
				logger.info "[INSERT_RESULT_CONSUMER][#{self.batchResultCount}][FAILURE] Inactivity detected for agency: '#{self.agency.key}' and GTFS File: '#{@GTFSFile.fileNameBase}' - Stopping job"
				clearInterval(intervalRef)
				self.deferred.reject(new JobInactivityTimeoutError(self.agency))
			else
				logger.info "[INSERT_RESULT_CONSUMER][#{self.batchResultCount}][SUCCESS] Activity detected for agency: '#{self.agency.key}' and GTFS File: '#{@GTFSFile.fileNameBase}' - Continuing job"
				self.previousBatchResultCount = self.batchResultCount
		, @timeout


	handleMessage: (channel, message) ->
		@inserted += message.inserted || 0
		@errors += message.errors || 0
		@batchResultCount += 1

		if !@agency.bounds
			@agency.bounds = { sw:[], ne:[] }

#		if message.agency && message.agency.bounds
#			logger.info "[MONGO][#{@batchCount}] Agency batch bounds: #{util.inspect(message.agency.bounds)}"

		if message.agency && message.agency.bounds
			@agency.bounds.sw[0] = message.agency.bounds.sw[0] if @agency.bounds.sw[0] > message.agency.bounds.sw[0] or not @agency.bounds.sw[0]
			@agency.bounds.ne[0] = message.agency.bounds.ne[0] if @agency.bounds.ne[0] < message.agency.bounds.ne[0] or not @agency.bounds.ne[0]
			@agency.bounds.sw[1] = message.agency.bounds.sw[1] if @agency.bounds.sw[1] > message.agency.bounds.sw[1] or not @agency.bounds.sw[1]
			@agency.bounds.ne[1] = message.agency.bounds.ne[1] if @agency.bounds.ne[1] < message.agency.bounds.ne[1] or not @agency.bounds.ne[1]
			@agency.center = [
				(@agency.bounds.ne[0] - @agency.bounds.sw[0]) / 2 + @agency.bounds.sw[0],
				(@agency.bounds.ne[1] - @agency.bounds.sw[1]) / 2 + @agency.bounds.sw[1]
			];


		logger.info "[INSERT_RESULT_CONSUMER][#{@batchResultCount}] Inserted lines: #{@inserted}, Errors:#{@errors} from process with pid: '#{message.process.pid}' - Agency [bounds: #{util.inspect(@agency?.bounds)}, center: #{@agency?.center}]"  if @batchResultCount % 100 == 0

		if @batchResultCountExpected && @batchResultCountExpected == @batchResultCount
			@deferred.fulfill({ agency: @agency, inserted: @inserted, errors: @errors, batchResultCount: @batchResultCount })


	configureBatchResultCountExpected: (batchResultCountExpected) ->
		@batchResultCountExpected = batchResultCountExpected


	promise: () ->
		@deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports = InsertedResultConsumer