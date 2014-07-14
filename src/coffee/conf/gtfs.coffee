########################################################################################
### Modules
########################################################################################

_ = require 'underscore'

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
### Config
########################################################################################

config =
#			agencies: [
#				# Put agency_key names from gtfs-data-exchange.com.
#                #Optionally, specify a download URL to use a dataset not from gtfs-data-exchange.com
#				'alamedaoakland-ferry',
#				{ agency_key: 'caltrain', url: 'http://www.gtfs-data-exchange.com/agency/caltrain/latest.zip'},
#				'ac-transit',
#				'county-connection',
#				'san-francisco-municipal-transportation-agency',
#				'bay-area-rapid-transit',
#				'golden-gate-ferry'
#			]
	agencies: [
		{ key: 'RATP', url: 'http://localhost/data/gtfs_paris_20140502.zip', inactivityTimeout: 30 * 1000 }
#		{ key: 'RATP', url: 'http://localhost/data/gtfs_paris_20140502-orig.zip', inactivityTimeout: 30 * 1000 }
#		{ key: 'NL', url: 'http://localhost/data/gtfs-nl.zip', inactivityTimeout: 30 * 1000 }
	]
#			agencies: [
#				{ key: 'Keolis', url: 'http://localhost/data/keolis-rennes_20101015_1538.zip' }
#			]
	files:[
		{ fileNameBase: 'agency', collection: Agency }
		{ fileNameBase: 'calendar_dates', collection: CalendarDate }
		{ fileNameBase: 'calendar', collection: Calendar }
		{ fileNameBase: 'fare_attributes', collection: FareAttribute }
		{ fileNameBase: 'fare_rules', collection: FareRule }
		{ fileNameBase: 'feed_info', collection: FeedInfo }
		{ fileNameBase: 'frequencies', collection: Frequencies }
		{ fileNameBase: 'routes', collection: Route }
		{ fileNameBase: 'stop_times', collection: StopTime }
		{ fileNameBase: 'stops', collection: Stop }
		{ fileNameBase: 'transfers', collection: Transfer }
		{ fileNameBase: 'trips', collection: Trip }
	]
	models:
		'agency': Agency
		'calendar_dates': CalendarDate
		'calendar': Calendar
		'fare_attributes': FareAttribute
		'fare_rules': FareRule
		'feed_info': FeedInfo
		'frequencies': Frequencies
		'routes': Route
		'stop_times': StopTime
		'stops': Stop
		'transfers': Transfer
		'trips': Trip



########################################################################################
### Exports
########################################################################################

module.exports = config



