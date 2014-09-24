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

	inserted = 0
	errors = 0

	constructor: (@gtfsFileBaseName) ->
		@amqpClient = amqp.createClient "GTFS_RECORDS_IMPORT_TASK"

	handleMessage: (channel, message, headers, deliveryInfo, messageObject) ->
		@run(message, headers, deliveryInfo, messageObject)


	run: (message, headers, deliveryInfo, messageObject) ->

		messageAcknowledged = true

		acknowledge = () ->
			if 	!messageAcknowledged
				messageObject.acknowledge(false)
				messageAcknowledged = true


		self = this
		if message.records.length == 0
			acknowledge()
		else
			arrayStream = new ArrayStream(message.records)
			csvStream = csv({ objectMode: true, newline:'\r\n', columns: true })
			batchStream = new BatchStream({ size : 1000, highWaterMark: 100 })

			arrayStream
			.pipe(csvStream)
			.pipe(batchStream)
			.on 'data', (records) ->
				gtfsRecordImporter.importLines(message.agency, self.gtfsFileBaseName, records)
				.then (result) ->
					inserted += result.inserted
					errors += result.errors
#					logger.info "[#{process.pid}][MONGO][SUCCESS][#{message.agency.key}][#{self.gtfsFileBaseName}][#{inserted}] Total lines inserted: #{inserted}" if Math.floor(inserted/10) % 100 == 0
					self.amqpClient.publishMessage "#{message.job.replyQueue}",
						inserted: result.inserted
						errors: result.errors
						agency: result.agency
						process:
							pid: process.pid
				.catch (err) ->
#					logger.info "[#{process.pid}][ERROR][#{err.type}][#{message.agency.key}][#{self.gtfsFileBaseName}][#{inserted}] #{err.message} - Stack: #{err.stack}"
					acknowledge()
			.on 'finish', (err) ->
				acknowledge()





########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask