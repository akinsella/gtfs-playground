########################################################################################
### Modules
########################################################################################

path = require 'path'
fs = require 'fs'
Promise = require 'bluebird'
csv = require 'csv-streamify'
split = require 'split'

gtfs = require '../conf/gtfs'
logger = require '../log/logger'
config = require '../conf/config'
amqp = require '../lib/amqp'

GtfsRecordsImportTask = require '../task/GtfsRecordsImportTask'

stream = require 'stream'
BatchStream = require 'batch-stream'
CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'
BokehTaskSubmitterStream = require '../stream/BokehTaskSubmitterStream'
AmqpTaskSubmitterStream = require '../stream/AmqpTaskSubmitterStream'



########################################################################################
### Broker & Workers
########################################################################################

amqpClient = amqp.createClient "GTFS_FILE_IMPORTER"

for agency in gtfs.agencies
	for gtfsFile in gtfs.files
		amqpClient.subscribeQueue "#{agency.key}.#{gtfsFile.fileNameBase}", new GtfsRecordsImportTask(agency, gtfsFile.fileNameBase)



########################################################################################
### Functions
########################################################################################


importGTFSFile = (agency, GTFSFile, downloadDir) ->

	deferred = Promise.pending()

	logger.info "Importing GTFS file: '#{GTFSFile.fileNameBase}' ..."

	filePath = path.join(downloadDir, "#{GTFSFile.fileNameBase}.txt")
	if !fs.existsSync(filePath)
		logger.info "File with path: '#{filePath}' does not exist"
		deferred.fulfill()
	else
		logger.info "#{agency.key}: '#{GTFSFile.fileNameBase}' Importing data"


		fsStream = fs.createReadStream(filePath)

		splitRead = 0
		splitStream = split()
		splitStream.on 'data', () ->
			splitRead++
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{splitRead}] Batch processed: #{splitRead}" if splitRead % 100000 == 0
		splitStream.on 'drain', () ->
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{splitRead}] drain"


		batchRead = 0
		batchStream = new BatchStream({ size : 10000, highWaterMark: 100 })
		batchStream.on 'data', () ->
			batchRead++
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] Batch processed: #{batchRead}" if batchRead % 100 == 0
		batchStream.on 'drain', () ->
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] drain"


		amqpRead = 0
		amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessRecord", { highWaterMark: 50, agency: agency, model: GTFSFile.fileNameBase })
		amqpTaskSubmitterStream.on 'data', () ->
			amqpRead++
			logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] AMQP reads: #{amqpRead}" if amqpRead % 100000 == 0
		amqpTaskSubmitterStream.on 'drain', () ->
			logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] drain"

		amqpTaskSubmitterStream


		fsStream
		.pipe(splitStream)
		.pipe(batchStream)
		.pipe(amqpTaskSubmitterStream).on 'finish', (err, data) ->
			if err
				deferred.reject(err)
			else
				deferred.fulfill(data)


	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	importGTFSFile: importGTFSFile