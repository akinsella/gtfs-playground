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
		count++

		agency_key = messages[0].agency.key
		model = messages[0].model
		index = messages[0].index

		gtfsRecordImporter.importLines(messages)
		.then (inserted) ->
			logger.info "[#{process.pid}][#{agency_key}][#{model}][#{index}] #{messages.length} lines inserted" if count % 1000 == 0
			if callback
				callback undefined, inserted.length

		.catch (err) ->
			console.log "[#{process.pid}][#{agency_key}][#{model}][#{index}] Error: #{err.message}"
			if callback
				callback err



########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask