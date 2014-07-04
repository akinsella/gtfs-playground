########################################################################################
### Modules
########################################################################################

devnull = require 'dev-null'

gtfs = require '../conf/gtfs'
logger = require '../log/logger'
gtfsRecordImporter = require './gtfsRecordImporter'
amqp = require '../lib/amqp'

csv = require 'csv-streamify'
BatchStream = require 'batch-stream'
ArrayStream = require '../stream/ArrayStream'
CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'



########################################################################################
### Class
########################################################################################

class GtfsRecordsImportTask

	count = 0

	constructor: (@gtfsFileBaseName) ->
		@amqpClient = amqp.createClient "GTFS_RECORDS_IMPORT_TASK"

	handleMessage: (channel, message, callback) ->
		@run(message, callback)


	run: (message, callback) ->

		self = this
		if message.records.length == 0
			if callback
				callback undefined, 0
		else
			arrayStream = new ArrayStream(message.records)
			csvStream = csv({ objectMode: true, newline:'\r\n', columns: true })
			batchStream = new BatchStream({ size : 100 })
			cl2oStream = new CsvLineToObjectStream( gtfs.models[@gtfsFileBaseName], message.agency.key,  { sw: [], ne: [] })

			arrayStream
			.pipe(csvStream)
			.pipe(batchStream)
#			.pipe(devnull({ objectMode: true }))
			.pipe(cl2oStream)
			.on 'data', (records) ->
				gtfsRecordImporter.importLines(message.agency, self.gtfsFileBaseName, records)
				.then (inserted) ->
					count += inserted
#					logger.info "[#{process.pid}][MONGO][SUCCESS][#{message.agency.key}][#{self.gtfsFileBaseName}][#{count}] Total lines inserted: #{count}" if Math.floor(count/10) % 100 == 0
					self.amqpClient.publishJSON "#{message.job.replyQueue}",
						inserted: inserted
				.catch (err) ->
#					logger.info "[#{process.pid}][ERROR][#{err.type}][#{message.agency.key}][#{self.gtfsFileBaseName}][#{count}] #{err.message} - Stack: #{err.stack}"

			.on 'finish', (err) ->
				if callback
					callback err




########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask