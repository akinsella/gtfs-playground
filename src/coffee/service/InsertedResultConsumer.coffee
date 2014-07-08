########################################################################################
### Modules
########################################################################################

util = require 'util'

logger = require '../log/logger'


########################################################################################
### Class
########################################################################################

class InsertedResultConsumer

	constructor: (@agency) ->
		@inserted = 0
		@errors = 0
		@batchCount = 0

	handleMessage: (channel, message) ->
		@inserted += message.inserted || 0
		@errors += message.errors || 0
		@batchCount += 1

		if !@agency.bounds
			@agency.bounds = { sw:[], ne:[] }

#		if message.agency && message.agency.bounds
#			logger.info "[MONGO][#{process.pid}][#{@batchCount}] Agency batch bounds: #{util.inspect(message.agency.bounds)}"

		if message.agency && message.agency.bounds
			@agency.bounds.sw[0] = message.agency.bounds.sw[0] if @agency.bounds.sw[0] > message.agency.bounds.sw[0] or not @agency.bounds.sw[0]
			@agency.bounds.ne[0] = message.agency.bounds.ne[0] if @agency.bounds.ne[0] < message.agency.bounds.ne[0] or not @agency.bounds.ne[0]
			@agency.bounds.sw[1] = message.agency.bounds.sw[1] if @agency.bounds.sw[1] > message.agency.bounds.sw[1] or not @agency.bounds.sw[1]
			@agency.bounds.ne[1] = message.agency.bounds.ne[1] if @agency.bounds.ne[1] < message.agency.bounds.ne[1] or not @agency.bounds.ne[1]
			@agency.center = [
				(@agency.bounds.ne[0] - @agency.bounds.sw[0]) / 2 + @agency.bounds.sw[0],
				(@agency.bounds.ne[1] - @agency.bounds.sw[1]) / 2 + @agency.bounds.sw[1]
			];


		logger.info "[MONGO][#{process.pid}][#{@batchCount}] Inserted lines: #{@inserted}, Errors:#{@errors} from process with pid: '#{message.process.pid}' - Agency [bounds: #{util.inspect(@agency?.bounds)}, center: #{@agency?.center}]"  if @batchCount % 100 == 0


########################################################################################
### Exports
########################################################################################

module.exports = InsertedResultConsumer