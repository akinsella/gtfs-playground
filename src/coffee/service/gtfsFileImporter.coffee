########################################################################################
### Modules
########################################################################################

path = require 'path'
fs = require 'fs'
Promise = require 'bluebird'
csv = require 'csv-streamify'
split = require 'split'
uuid = require 'uuid'

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

for gtfsFile in gtfs.files
	amqpClient.subscribeQueue "#{gtfsFile.fileNameBase}", new GtfsRecordsImportTask(gtfsFile.fileNameBase)


########################################################################################
### Classes
########################################################################################

class InsertedResultConsumer

	constructor: () ->
		@inserted = 0
		@batchCount = 0

	handleMessage: (channel, message, callback) ->
		@inserted += message.inserted || 0
		@batchCount += 1

		logger.info "[MONGO] Inserted lines: #{@inserted}" if @batchCount % 100 == 0

		if callback
			callback()



########################################################################################
### Functions
########################################################################################


importGTFSFile = (agency, GTFSFile, downloadDir) ->

	jobUuid = uuid.v4()

	firstLine = ''

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
		splitStream.on 'data', (line) ->
			if splitRead == 0
				firstLine = line
			splitRead++
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{splitRead}] Batch processed: #{splitRead}" if splitRead % 100000 == 0
		splitStream.on 'drain', () ->
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{splitRead}] drain"


		batchRead = 0
		batchStream = new BatchStream({ size : 1000, highWaterMark: 100 })
		batchStream.on 'data', () ->
			batchRead++
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] Batch processed: #{batchRead}" if batchRead % 100 == 0
		batchStream.on 'drain', () ->
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] drain"


		amqpRead = 0


		replyQueueJobUuid = jobUuid.replace(/-/g,"_")
		replyQueue = "#{GTFSFile.fileNameBase}_result_#{replyQueueJobUuid}".toUpperCase()

		amqpClient.subscribeQueue replyQueue, new InsertedResultConsumer()

		amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessRecord", {
			highWaterMark: 50,
			agency: agency,
			model: GTFSFile.fileNameBase,
			job: {
				replyQueue: replyQueue
				uuid: jobUuid
			},
			firstLine: () -> if batchRead == 0 then undefined else firstLine
		})
		amqpTaskSubmitterStream.on 'data', () ->
			amqpRead++
			logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] AMQP reads: #{amqpRead}" if amqpRead % 100000 == 0
		amqpTaskSubmitterStream.on 'drain', () ->
			logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] drain"

		amqpTaskSubmitterStream


		fsStream
		.pipe(splitStream)
		.pipe(batchStream)
		.pipe(amqpTaskSubmitterStream)
		.on 'finish', (err, data) ->
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