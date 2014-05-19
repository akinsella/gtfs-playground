########################################################################################
### Modules
########################################################################################

request = require 'request'
exec = require('child_process').exec
fs = require 'fs'
path = require 'path'
csv = require 'csv-streamify'
async = require 'async'
unzip = require 'unzip'
Q = require 'q'
bokeh  = require 'zmq-bokeh'
heapdump = require 'heapdump'
util = require 'util'
stream = require 'stream'
BatchStream = require 'batch-stream'

mongo = require '../lib/mongo'
config = require '../conf/config'
logger = require '../log/logger'

CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'
BokehTaskSubmitterStream = require '../stream/BokehTaskSubmitterStream'

GtfsRecordsImportTask = require '../task/GtfsRecordsImportTask'

archiveDownloader = require './archiveDownloader'

Agency = require '../model/agency'
Calendar = require '../model/calendar'
CalendarDate = require '../model/calendarDate'
Route = require '../model/route'
Stop = require '../model/stop'
StopTime = require '../model/stopTime'
Trip = require '../model/trip'
Frequencies = require '../model/frequencies'
FareAttribute = require '../model/fareAttribute'
FareRule = require '../model/fareRule'
FeedInfo = require '../model/feedInfo'
Transfer = require '../model/transfer'



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
### Init
########################################################################################

importAgency = (agency, GTFSFiles, downloadDir, cb) ->

	cleanupFiles = (cb) ->
		command = if process.platform.match(/^win/) then  "rmdir /Q /S " else "rm -rf "
		exec "#{command} #{downloadDir}", (err, stdout, stderr) ->
			if err
				cb(err)
			else
				fs.mkdir downloadDir, cb

	downloadFiles = (cb) ->
		archiveDownloader.downloadArchive(agency.url, downloadDir, cb)


	removeDatabase = (cb) ->
		removeDatabaseAction = (GTFSFile, cb) ->
			logger.info "Removing database collection: '#{GTFSFile.collection.modelName}' ..."
			GTFSFile.collection.remove { agency_key: agency_key }, cb
			logger.info "Removed database collection: '#{GTFSFile.collection.modelName}'"

		async.each GTFSFiles, removeDatabaseAction, (err) ->
			logger.info "Removed data from collections"
			cb err, "remove"


	importFiles = (cb) ->
		logger.info "Importing GTFS files ..."

		gtfsFileProcessor = (GTFSFile, cb) ->
			logger.info "Importing GTFS file: '#{GTFSFile.fileNameBase}' ..."

			filePath = path.join(downloadDir, "#{GTFSFile.fileNameBase}.txt")
			return cb() unless fs.existsSync(filePath)

			logger.info "#{agency_key}: '#{GTFSFile.fileNameBase}' Importing data"

			fsStream = fs.createReadStream(filePath)
			cvsStream = csv({ objectMode: true, newline:'\r\n' })

			cl2oStream = new CsvLineToObjectStream( GTFSFile, agency.key,  { sw: [], ne: [] })
			batchStream = new BatchStream({ size : 1000 })
			bokehTaskSubmitterStream = new BokehTaskSubmitterStream(client, "ProcessRecord")
			bokehTaskSubmitterStream.on 'end', cb

			fsStream.pipe(cvsStream).pipe(cl2oStream).pipe(batchStream).pipe(bokehTaskSubmitterStream)

		async.eachSeries GTFSFiles, gtfsFileProcessor, (e) ->
			logger.info "Imported GTFS files ..."
			cb e, "import"

	postProcess = (cb) ->
		logger.info "#{agency_key}:  Post Processing data"
		async.series [ agencyCenter, longestTrip, updatedDate ], (e, results) ->
			cb()

	agencyCenter = (cb) ->
		query = { agency_key: agency_key }
		updateData = { $set: {
			agency_bounds: agency_bounds,
			agency_center: [
					(agency_bounds.ne[0] - agency_bounds.sw[0]) / 2 + agency_bounds.sw[0]
					(agency_bounds.ne[1] - agency_bounds.sw[1]) / 2 + agency_bounds.sw[1]
			] }
		}
		Agency.update query, updateData, cb

	longestTrip = (cb) ->
		###
			Trips.find({agency_key: agency_key}).for.toArray (e, trips) ->
				async.each trips, (trip, cb) ->
					mongo.client.collection('stoptimes', (e, collection) ->

					logger.info(trip);
					cb()
		###
		cb()

	updatedDate = (cb) ->
		query = { agency_key: agency_key }
		updateData = { $set: { date_last_updated: Date.now() } }
		Agency.update query, updateData, cb

	agency_key = agency.key
	agency_bounds =
		sw: []
		ne: []

	logger.info "Starting '#{agency_key}' agency"
	async.series [ cleanupFiles, downloadFiles, removeDatabase, importFiles, postProcess, cleanupFiles], (e, results) ->
		logger.info "#{e or agency_key}: Completed"
		cb()



########################################################################################
### Exports
########################################################################################

module.exports =
	importAgency: importAgency