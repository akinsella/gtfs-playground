########################################################################################
### Modules
########################################################################################

request = require 'request'
exec = require('child_process').exec
fs = require 'fs'
path = require 'path'
csv = require 'csv'
async = require 'async'
unzip = require 'unzip'
Q = require 'q'
heapdump = require 'heapdump'

mongo = require '../lib/mongo'
config = require '../conf/config'
logger = require '../log/logger'


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
### Init dealers and brokers
########################################################################################

init = () ->
	logger.info "Initializing GTFSImportService on worker with pid: #{process.pid}"


class ProcessRecord

	count = 0

	run: (messages, callback) ->
		jsonMessages = messages

		lines = jsonMessages.map (jsonMessage) ->

			agency_key = jsonMessage.agency.key
			agency_bounds = jsonMessage.agency.bounds
			line = jsonMessage.line

			for key of line
				delete line[key]  if line[key] is null

			line.agency_key = agency_key
			line.stop_sequence = parseInt(line.stop_sequence, 10)  if line.stop_sequence
			line.direction_id = parseInt(line.direction_id, 10)  if line.direction_id

			if line.stop_lat and line.stop_lon
				line.loc = [ parseFloat(line.stop_lon), parseFloat(line.stop_lat) ]
				agency_bounds.sw[0] = line.loc[0]  if agency_bounds.sw[0] > line.loc[0] or not agency_bounds.sw[0]
				agency_bounds.ne[0] = line.loc[0]  if agency_bounds.ne[0] < line.loc[0] or not agency_bounds.ne[0]
				agency_bounds.sw[1] = line.loc[1]  if agency_bounds.sw[1] > line.loc[1] or not agency_bounds.sw[1]
				agency_bounds.ne[1] = line.loc[1]  if agency_bounds.ne[1] < line.loc[1] or not agency_bounds.ne[1]

			line

		agency_key = jsonMessages[0].agency.key
		model = jsonMessages[0].model
		index = jsonMessages[0].index

		models[model].create lines, (err, inserted) ->
			count++

#			if count % 100 == 0
#				heapdump.writeSnapshot()

			if err
				console.log "[#{process.pid}][#{agency_key}][#{model}][#{index}] Error: #{err.message}"
			if !inserted
				logger.info "[#{process.pid}][#{agency_key}][#{model}][#{index}] Line could not be inserted"
			else
				logger.info "[#{process.pid}][#{agency_key}][#{model}][#{index}] Line inserted"

			callback(err, inserted)


bokeh  = require 'zmq-bokeh'

broker = new bokeh.Broker config.bokeh
logger.info "[#{process.pid}] Initialized bokeh broker"
client = new bokeh.Client config.bokeh
logger.info "[#{process.pid}] Initialized bokeh client"
worker = new bokeh.Worker config.bokeh
logger.info "[#{process.pid}] Initialized bokeh worker"
worker.registerTask "ProcessRecord", ProcessRecord


########################################################################################
### Variables
########################################################################################

downloadDir = 'downloads'

models =
	"Agency": Agency
	"CalendarDate": CalendarDate
	"Calendar": Calendar
	"FareAttribute": FareAttribute
	"FareRule": FareRule
	"FeedInfo": FeedInfo
	"Frequencies": Frequencies
	"Route": Route
	"StopTime": StopTime
	"Stop": Stop
	"Transfer": Transfer
	"Trip": Trip


GTFSFiles = [
	{
		fileNameBase: "agency"
		collection: Agency
	},
	{
		fileNameBase: "calendar_dates"
		collection: CalendarDate
	},
	{
		fileNameBase: "calendar"
		collection: Calendar
	},
	{
		fileNameBase: "fare_attributes"
		collection: FareAttribute
	},
	{
		fileNameBase: "fare_rules"
		collection: FareRule
	},
	{
		fileNameBase: "feed_info"
		collection: FeedInfo
	},
	{
		fileNameBase: "frequencies"
		collection: Frequencies
	},
	{
		fileNameBase: "routes"
		collection: Route
	},
	{
		fileNameBase: "stop_times"
		collection: StopTime
	},
	{
		fileNameBase: "stops"
		collection: Stop
	},
	{
		fileNameBase: "transfers"
		collection: Transfer
	},
	{
		fileNameBase: "trips"
		collection: Trip
	}
]


########################################################################################
### Functions
########################################################################################

handleError = (err) ->
	logger.info "[ERROR][Name:#{err.name}] #{err.message}"
	throw err


importData = () ->
	deferred = Q.defer()

	taskQueue = async.queue(downloadGTFS, 1)

	config.gtfs.agencies.forEach (item) ->
		if typeof (item) is "string"
			agency =
				agency_key: item
				agency_url: "http://www.gtfs-data-exchange.com/agency/#{item}/latest.zip"
		else
			agency =
				agency_key: item.agency_key
				agency_url: item.url

		if not agency.agency_key or not agency.agency_url
			handleError new Error("No URL or Agency Key provided.")

		taskQueue.push agency


	taskQueue.drain = (err) ->
		logger.info "[QUEUE][DRAIN] All agencies completed (#{config.gtfs.agencies.length} total)"
		if err
			logger.info "[QUEUE][DRAIN] Got a error: #{err.message}"
			deferred.reject err
		else
			deferred.resolve config.gtfs.agencies.length

	deferred.promise


downloadGTFS = (task, cb) ->
	cleanupFiles = (cb) ->
		command = if process.platform.match(/^win/) then  "rmdir /Q /S " else "rm -rf "
		exec "#{command} #{downloadDir}", (err, stdout, stderr) ->
			try
				fs.mkdirSync downloadDir
				cb()
			catch err
				if err.code is "EEXIST"
					cb()
				else
					handleError err

	downloadFiles = (cb) ->

		logger.info "Downloading file with URL: '#{agency_url}'"
		processFile = (err, response, body) ->
			cb new Error("Couldn't download files")  if response and response.statusCode isnt 200
			logger.info "File with URL: '#{agency_url}' downloaded"
			fs.createReadStream(downloadDir + "/latest.zip").pipe(unzip.Extract(path: downloadDir).on("close", cb)).on "error", handleError

		request(agency_url, processFile).pipe fs.createWriteStream(downloadDir + "/latest.zip")

	removeDatabase = (cb) ->
		removeDatabaseAction = (GTFSFile, cb) ->
			logger.info "Removing database collection: '#{GTFSFile.collection.modelName}' ..."
			GTFSFile.collection.remove { agency_key: agency_key }, cb
			logger.info "Removed database collection: '#{GTFSFile.collection.modelName}'"

		async.each GTFSFiles, removeDatabaseAction, (err) ->
			logger.info "Removed data from collections"
			cb err, "remove"


	importFiles = (cb) ->

		records = []
		logger.info "Importing GTFS files ..."
		gtfsFileProcessor = (GTFSFile, cb) ->
			logger.info "Importing GTFS file: '#{GTFSFile.fileNameBase}' ..."
			if GTFSFile
				filepath = path.join(downloadDir, "#{GTFSFile.fileNameBase}.txt")
				return cb() unless fs.existsSync(filepath)
				logger.info "#{agency_key}: '#{GTFSFile.fileNameBase}' Importing data"
				csv().from.path(filepath, { columns: true })
				.on "record", (line, index) ->
					logger.info "[#{index}] push.send" if index % 10000 == 0

					records.push
						model: GTFSFile.collection.modelName
						index: index
						line: line
						agency:
							key: agency_key
							bounds: agency_bounds

					if records.length == 1000

#						processEntries records, (err, data) ->
#							logger.info "[#{index}] push.send" if index % 10000 == 0
						client.submitTask "ProcessRecord", records, (error, data) ->
							logger.info "[#{index}] push.send" if index % 10000 == 0

						records = []

				.on "end", (count) ->
					client.submitTask "ProcessRecord", records, (error, data) ->
						logger.info "[---] push.send ended"
					cb()
				.on "error", handleError

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

	agency_key = task.agency_key
	agency_bounds =
		sw: []
		ne: []

	agency_url = task.agency_url
	logger.info "Starting '#{agency_key}' agency"
	async.series [ cleanupFiles, downloadFiles, removeDatabase, importFiles, postProcess, cleanupFiles], (e, results) ->
		logger.info "#{e or agency_key}: Completed"
		cb()


########################################################################################
### exports
########################################################################################

module.exports =
	init: init
	importData: importData