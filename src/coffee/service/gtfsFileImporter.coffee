########################################################################################
### Modules
########################################################################################

path = require 'path'
fs = require 'fs'
Promise = require 'bluebird'
csv = require 'csv-streamify'
split = require 'split'

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

#broker = new bokeh.Broker config.bokeh
#logger.info "[#{process.pid}] Initialized bokeh broker"
#
#worker = new bokeh.Worker config.bokeh
#logger.info "[#{process.pid}] Initialized bokeh worker"
#worker.registerTask "ProcessRecord", GtfsRecordsImportTask
#
#client = new bokeh.Client config.bokeh
#logger.info "[#{process.pid}] Initialized bokeh client"

amqpClient = amqp.createClient "GTFS_FILE_IMPORTER"
amqpClient.subscribeQueue "ProcessRecord", new GtfsRecordsImportTask()



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
		csvLinesRead = 0
		c2loLinesRead = 0
		batchRead = 0
		amqpRead = 0

		fsStream = fs.createReadStream(filePath)
		csvStream = csv({ objectMode: true, newline: '\r\n', highWaterMark: 10000 })
		csvStream.on 'data', () ->
			csvLinesRead++
			logger.info "[CSV][#{GTFSFile.fileNameBase}][#{csvLinesRead}] CSV lines read: #{csvLinesRead}" if csvLinesRead % 1000 == 0

		cl2oStream = new CsvLineToObjectStream(GTFSFile, agency.key, { sw: [], ne: [] }, { highWaterMark: 8000 })
		cl2oStream.on 'data', () ->
			c2loLinesRead++
			logger.info "[C2LO][#{GTFSFile.fileNameBase}][#{c2loLinesRead}] CL2O processed: #{c2loLinesRead}" if c2loLinesRead % 1000 == 0
		batchStream = new BatchStream({ size : 2000, highWaterMark: 20 })
		batchStream.on 'data', () ->
			batchRead++
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] Batch processed: #{batchRead}" if batchRead % 100 == 0
		batchStream.on 'drain', (err, data) ->
			logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{amqpRead}] drain"
		amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessRecord", { highWaterMark: 18 })
		amqpTaskSubmitterStream.on 'data', () ->
			amqpRead++
			logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] AMQP reads: #{amqpRead}" if amqpRead % 1000 == 0
		amqpTaskSubmitterStream.on 'drain', (err, data) ->
			logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] drain"
		amqpTaskSubmitterStream.on 'finish', (err, data) ->
			if err
				deferred.reject(err)
			else
				deferred.fulfill(data)

		fsStream
		.pipe(csvStream)
		.pipe(cl2oStream)
		.pipe(batchStream)
		.pipe(amqpTaskSubmitterStream)
	#	fsStream.pipe(csvStream).pipe(cl2oStream).pipe(batchStream).pipe(amqpTaskSubmitterStream)


	#	bokehTaskSubmitterStream = new BokehTaskSubmitterStream(client, "ProcessRecord")
	#	bokehTaskSubmitterStream.on 'end', deferred.makeNodeResolver()

	#	fsStream.pipe(csvStream).pipe(cl2oStream).pipe(batchStream).pipe(bokehTaskSubmitterStream)

	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	importGTFSFile: importGTFSFile