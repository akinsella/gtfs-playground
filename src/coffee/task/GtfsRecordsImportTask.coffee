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
			cl2oStream = new CsvLineToObjectStream( gtfs.models[@gtfsFileBaseName], message.agency.key,  { sw: [], ne: [] })

			arrayStream
			.pipe(csvStream)
			.pipe(batchStream)
#			.pipe(devnull({ objectMode: true }))
			.pipe(cl2oStream)
			.on 'data', (records) ->
				gtfsRecordImporter.importLines(message.agency, self.gtfsFileBaseName, records)
				.then (result) ->
					count += result.inserted
#					logger.info "[#{process.pid}][MONGO][SUCCESS][#{message.agency.key}][#{self.gtfsFileBaseName}][#{count}] Total lines inserted: #{count}" if Math.floor(count/10) % 100 == 0
					self.amqpClient.publishJSON "#{message.job.replyQueue}",
						inserted: result.inserted
						agency: result.agency
						process:
							pid: process.pid
				.catch (err) ->
#					logger.info "[#{process.pid}][ERROR][#{err.type}][#{message.agency.key}][#{self.gtfsFileBaseName}][#{count}] #{err.message} - Stack: #{err.stack}"
					acknowledge()
			.on 'finish', (err) ->
				acknowledge()





########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask