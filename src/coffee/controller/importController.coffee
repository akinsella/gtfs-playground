########################################################################################
### Modules
########################################################################################

config = require '../conf/config'
logger = require '../log/logger'
gtfsImportService = require '../service/gtfsImportService'

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
### Variables
########################################################################################

GTFSFiles = [
	{ fileNameBase: "agency", collection: Agency }
	{ fileNameBase: "calendar_dates", collection: CalendarDate }
	{ fileNameBase: "calendar", collection: Calendar }
	{ fileNameBase: "fare_attributes", collection: FareAttribute }
	{ fileNameBase: "fare_rules", collection: FareRule }
	{ fileNameBase: "feed_info", collection: FeedInfo }
	{ fileNameBase: "frequencies", collection: Frequencies }
	{ fileNameBase: "routes", collection: Route }
	{ fileNameBase: "stop_times", collection: StopTime }
	{ fileNameBase: "stops", collection: Stop }
	{ fileNameBase: "transfers", collection: Transfer }
	{ fileNameBase: "trips", collection: Trip }
]


########################################################################################
### Functions
########################################################################################

importData = (req, res) ->
	gtfsImportService.importData(config.gtfs.agencies, GTFSFiles, 'downloads')
	.then (agencyCount) ->
		logger.info "[GTFS][IMPORT] Imported #{agencyCount} agencies data"
	.catch (err) ->
		logger.info "[GTFS][IMPORT] Failed with error: #{err.message} - #{err.stack}"
		res.send 500, err.message



########################################################################################
### Exports
########################################################################################

module.exports =
	importData: importData