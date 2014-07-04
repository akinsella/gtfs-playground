########################################################################################
### Modules
########################################################################################

path = require 'path'
fs = require 'fs'
Promise = require 'bluebird'
split = require 'split'

gtfs = require '../conf/gtfs'
logger = require '../log/logger'
config = require '../conf/config'
amqp = require '../lib/amqp'

InsertedResultConsumer = require './InsertedResultConsumer'

BatchStream = require 'batch-stream'
CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'
AmqpTaskSubmitterStream = require '../stream/AmqpTaskSubmitterStream'


########################################################################################
### Broker & Workers
########################################################################################

amqpClient = amqp.createClient "GTFS_FILE_IMPORTER"


########################################################################################
### Functions
########################################################################################


importGTFSFile = (job, agency, GTFSFile, downloadDir) ->

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


		replyQueueJobUuid = job.uuid.replace(/-/g,"_")
		replyQueue = "#{GTFSFile.fileNameBase}_result_#{replyQueueJobUuid}".toUpperCase()

		amqpClient.subscribeQueue replyQueue, new InsertedResultConsumer()

		amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessRecord", {
			highWaterMark: 50,
			agency: agency,
			model: GTFSFile.fileNameBase,
			job: {
				replyQueue: replyQueue
				uuid: job.uuid
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