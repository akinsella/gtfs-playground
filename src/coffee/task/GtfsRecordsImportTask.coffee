########################################################################################
### Modules
########################################################################################

Q = require 'q'

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
### Class
########################################################################################

class GtfsRecordsImportTask

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

	count = 0

	constructor: (@models) ->


	run: (messages, callback) ->
		count++

		logger.info "[#{process.pid}][#{count}] Processing #{messages.length} records ..."
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

		Q.when(models[model].create(lines))
		.then (inserted) ->
			logger.info "[#{process.pid}][#{agency_key}][#{model}][#{index}] #{inserted.length} lines inserted"
			callback undefined, inserted.length

		.fail (err) ->
			console.log "[#{process.pid}][#{agency_key}][#{model}][#{index}] Error: #{err.message}"
			callback err



########################################################################################
### Exports
########################################################################################

module.exports = GtfsRecordsImportTask