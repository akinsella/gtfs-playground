########################################################################################
### Modules
########################################################################################

gtfs = require '../conf/gtfs'
logger = require '../log/logger'
gtfsRecordImporter = require './gtfsRecordImporter'


########################################################################################
### Class
########################################################################################

class GtfsRecordsImportTask

	count = 0

	constructor: (@agency, @gtfsFileBaseName) ->

	handleMessage: (channel, message, callback) ->
		@run(message, callback)


	run: (message, callback) ->

		if message.data.length == 0
			if callback
				callback undefined, 0
		else
			agency_key = @agency.key

			gtfsRecordImporter.importLines(@agency, @gtfsFileBaseName, message.data)
			.then (inserted) ->
				count += inserted
				logger.info "[MONGO][#{process.pid}][#{agency_key}][#{@gtfsFileBaseName}][#{count}] Total lines inserted: #{count}" if Math.floor(count/10) % 100 == 0
				if callback
					callback undefined, inserted.length

			.catch (err) ->
				console.log "[#{process.pid}][#{agency_key}][#{@gtfsFileBaseName}][#{count}] Error: #{err.message} - Stack: #{err.stack}"
				if callback
					callback err



########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask