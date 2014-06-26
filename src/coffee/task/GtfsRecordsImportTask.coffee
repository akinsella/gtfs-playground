########################################################################################
### Modules
########################################################################################

logger = require '../log/logger'
gtfsRecordImporter = require './gtfsRecordImporter'

########################################################################################
### Class
########################################################################################

class GtfsRecordsImportTask

	count = 0

	handleMessage: (channel, messages, callback) ->
		@run(messages, callback)


	run: (messages, callback) ->

		if messages.length == 0
			if callback
				callback undefined, 0
		else

			count += messages.length

			agency_key = messages[0].agency.key
			model = messages[0].model
			index = messages[0].index

			gtfsRecordImporter.importLines(messages)
			.then (inserted) ->
				logger.info "[MONGO][#{process.pid}][#{agency_key}][#{model}][#{index}] Total lines inserted: #{count}" if Math.floor(count/10) % 100 == 0
				if callback
					callback undefined, inserted.length

			.catch (err) ->
				console.log "[#{process.pid}][#{agency_key}][#{model}][#{index}] Error: #{err.message} - Stack: #{err.stack}"
				if callback
					callback err



########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask