########################################################################################
### Modules
########################################################################################

path = require 'path'
fs = require 'fs'
Q = require 'q'
csv = require 'csv-streamify'
bokeh  = require 'zmq-bokeh'

logger = require '../log/logger'
config = require '../conf/config'

GtfsRecordsImportTask = require '../task/GtfsRecordsImportTask'

stream = require 'stream'
BatchStream = require 'batch-stream'
CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'
BokehTaskSubmitterStream = require '../stream/BokehTaskSubmitterStream'



########################################################################################
### Broker & Workers
########################################################################################

broker = new bokeh.Broker config.bokeh
logger.info "[#{process.pid}] Initialized bokeh broker"

worker = new bokeh.Worker config.bokeh
logger.info "[#{process.pid}] Initialized bokeh worker"
worker.registerTask "ProcessRecord", GtfsRecordsImportTask

client = new bokeh.Client config.bokeh
logger.info "[#{process.pid}] Initialized bokeh client"



########################################################################################
### Functions
########################################################################################

importGTFSFile = (agency, GTFSFile, downloadDir) ->

	deferred = Q.defer()

	logger.info "Importing GTFS file: '#{GTFSFile.fileNameBase}' ..."

	filePath = path.join(downloadDir, "#{GTFSFile.fileNameBase}.txt")
	if !fs.existsSync(filePath)
		deferred.reject(new Error("File with path: '#{filePath}' does not exist"))
		return

	logger.info "#{agency.key}: '#{GTFSFile.fileNameBase}' Importing data"

	fsStream = fs.createReadStream(filePath)
	cvsStream = csv({ objectMode: true, newline:'\r\n' })

	cl2oStream = new CsvLineToObjectStream( GTFSFile, agency.key,  { sw: [], ne: [] })
	batchStream = new BatchStream({ size : 1000 })
	bokehTaskSubmitterStream = new BokehTaskSubmitterStream(client, "ProcessRecord")
	bokehTaskSubmitterStream.on 'end', deferred.makeNodeResolver()

	fsStream.pipe(cvsStream).pipe(cl2oStream).pipe(batchStream).pipe(bokehTaskSubmitterStream)

	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	importGTFSFile: importGTFSFile