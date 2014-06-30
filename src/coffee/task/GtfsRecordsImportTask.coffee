########################################################################################
### Modules
########################################################################################

devnull = require 'dev-null'

gtfs = require '../conf/gtfs'
logger = require '../log/logger'
gtfsRecordImporter = require './gtfsRecordImporter'

csv = require 'csv-streamify'
BatchStream = require 'batch-stream'
Stream = require 'stream'
CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'


class ArrayStream extends Stream.Readable
	constructor: (@array) ->
		super()

	_read: () ->
		if @array.length == 0
			@push null
		else
			@push(@array[0] + '\r\n');
			@array.shift()


########################################################################################
### Class
########################################################################################

class GtfsRecordsImportTask

	count = 0

	constructor: (@gtfsFileBaseName) ->


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
			batchStream = new BatchStream({ size : 1000 })
			cl2oStream = new CsvLineToObjectStream( gtfs.models[@gtfsFileBaseName], message.agency.key,  { sw: [], ne: [] })

			arrayStream
			.pipe(csvStream)
			.pipe(batchStream)
#			.pipe(devnull({ objectMode: true }))
			.pipe(cl2oStream)
			.on 'data', (records) =>

				gtfsRecordImporter.importLines(message.agency, self.gtfsFileBaseName, records)
				.then (inserted) ->
					count += inserted
#					logger.info "[MONGO][#{process.pid}][#{message.agency.key}][#{self.gtfsFileBaseName}][#{count}] Total lines inserted: #{count}" if Math.floor(count/10) % 100 == 0

				.catch (err) ->
					console.log "[#{process.pid}][#{message.agency.key}][#{self.gtfsFileBaseName}][#{count}] Error: #{err.message} - Stack: #{err.stack}"

			.on 'finish', (err) ->
				if callback
					callback err




########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask