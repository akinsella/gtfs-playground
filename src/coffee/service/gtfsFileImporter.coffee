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

		fsStream = fs.createReadStream(filePath)
		csvStream = csv({ objectMode: true, newline:'\r\n', ###highWaterMark: 1### })

		lineIndex = 0

		cl2oStream = new CsvLineToObjectStream( GTFSFile, agency.key,  { sw: [], ne: [] }, { ###highWaterMark: 1### })
		batchStream = new BatchStream({ size : 10, highWaterMark: 10000 })
		amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessRecord", { highWaterMark: 100 })
		amqpTaskSubmitterStream.on 'finish', (err, data) ->
			if err
				deferred.reject(err)
			else
				deferred.fulfill(data)

		fsStream
		.pipe(csvStream)
		.pipe(cl2oStream)
		.on 'data', (data) ->
			lineIndex++
			logger.info "[#{GTFSFile.fileNameBase}][#{lineIndex}] Processed data" if lineIndex % 10000 == 0
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