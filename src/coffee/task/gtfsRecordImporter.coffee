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
### Variables
########################################################################################

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


########################################################################################
### Class
########################################################################################

importLines = (jsonMessages) ->
	lines = jsonMessages.map (jsonMessage) ->

		agencyKey = jsonMessage.agency.key
		agencyBounds = jsonMessage.agency.bounds
		line = jsonMessage.line

		for key of line
			delete line[key]  if line[key] is null

		line.agency_key = agencyKey
		line.stop_sequence = parseInt(line.stop_sequence, 10)  if line.stop_sequence
		line.direction_id = parseInt(line.direction_id, 10)  if line.direction_id

		if line.stop_lat and line.stop_lon
			line.loc = [ parseFloat(line.stop_lon), parseFloat(line.stop_lat) ]
			agencyBounds.sw[0] = line.loc[0]  if agencyBounds.sw[0] > line.loc[0] or not agencyBounds.sw[0]
			agencyBounds.ne[0] = line.loc[0]  if agencyBounds.ne[0] < line.loc[0] or not agencyBounds.ne[0]
			agencyBounds.sw[1] = line.loc[1]  if agencyBounds.sw[1] > line.loc[1] or not agencyBounds.sw[1]
			agencyBounds.ne[1] = line.loc[1]  if agencyBounds.ne[1] < line.loc[1] or not agencyBounds.ne[1]

		line

	model = jsonMessages[0].model

	Q.when(models[model].create(lines))



########################################################################################
### Exports
########################################################################################

module.exports =
	importLines: importLines