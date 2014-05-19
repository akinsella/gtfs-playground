########################################################################################
### Modules
########################################################################################

async = require 'async'
_ = require 'underscore'
moment = require 'moment'

logger = require '../log/logger'
utils = require '../lib/utils'

Agency = require '../models/Agency'
Calendar = require '../models/Calendar'
Route = require '../models/CalendarDate'
Stop = require '../models/FareAttribute'
StopTime = require '../models/FareRule'
Trip = require '../models/FeedInfo'
Frequencies = require '../models/Frequencies'


########################################################################################
### Functions
########################################################################################

handleError = (e) ->
	console.error e or "Unknown Error"
	process.exit 1

agencies = (cb) ->
	Agency.find({}, cb)


getRoutesByAgency = (agency_key, cb) ->
	Route.find({ agency_key: agency_key } , cb)


getAgenciesByDistance = (lat, lon, radius, cb) ->

	#gets all agencies within a radius
	if _.isFunction(radius)
		cb = radius
		radius = 25 # default is 25 miles
	lat = parseFloat(lat)
	lon = parseFloat(lon)
	radiusInDegrees = Math.round(radius / 69 * 100000) / 100000
	Agency
		.where("agency_center")
		.near(lon, lat)
		.maxDistance(radiusInDegrees)
		.exec(cb)


getRoutesByDistance = (lat, lon, radius, cb) ->

	#gets all routes within a radius
	if _.isFunction(radius)
		cb = radius
		radius = 1 #default is 1 mile

	lat = parseFloat(lat)
	lon = parseFloat(lon)
	radiusInDegrees = Math.round(radius / 69 * 100000) / 100000

	stop_ids = []
	trip_ids = []
	route_ids = []
	routes = []

	async.series [
		getStopsNearby
		getTrips
		getRoutes
		lookupRoutes
	], (e, results) ->
		cb e, routes

	getStopsNearby = (cb) ->
		Stop
		.where("loc")
		.near(lon, lat)
		.maxDistance(radiusInDegrees)
		.exec((e, stops) ->
			if stops.length
				stops.forEach (stop) ->
					stop_ids.push stop.stop_id  if stop.stop_id
					return

				cb e, "stops"
			else
				cb new Error("No stops within " + radius + " miles"), "stops"
		)

	getTrips = (cb) ->
		StopTime
			.distinct('trip_id')
			.where('stop_id').in(stop_ids)
			.exec((e, results) ->
				trip_ids = results
				cb(e, 'trips')
			)

	getRoutes = (cb) ->
		Trip
			.distinct('route_id')
			.where('trip_id').in(trip_ids)
			.exec((e, results) ->
				if (results.length)
					route_ids = results
					cb(null, 'routes')
				else
					cb(new Error('No routes to any stops within ' + radius + ' miles'), 'routes')
			)

	lookupRoutes = (cb) ->
		Route
			.where('route_id')
			.in(route_ids)
			.exec((e, results) ->
				if(results.length)
					routes = results
					cb(null, 'lookup')
				else
					cb(new Error('No information for routes'), 'lookup')
			)


getStopsByRoute = (agency_key, route_id, direction_id, cb) ->

	if _.isFunction(direction_id)
		cb = direction_id
		direction_id = null

	stopTimes = []
	longestTrip = []
	stops = []
	trip_ids = []
	stop_ids = []

	async.series [
		getTrips
		getStopTimes
		getStops
	], (e, results) ->
		cb e, stops

	#gets stops for one route
	getTrips = (cb) ->
		tripQuery =
			agency_key: agency_key
			route_id: route_id

		if direction_id
			tripQuery.direction_id = direction_id
		else
			#This doesn't really work - direction_id : null should match ALL direction IDs! (Ivan TODO)
			tripQuery["$or"] = [ { direction_id: null }, { direction_id: 0 } ]
		Trip
			.count tripQuery, (e, tripCount) ->
				if tripCount

					#grab up to 30 random samples from trips to find longest one
					count = 0
					async.whilst (->
						count < ((if (tripCount > 30) then 30 else tripCount))
					), ((cb) ->
						count++
						Trip.findOne(tripQuery).skip(Math.floor(Math.random() * tripCount)).exec (e, trip) ->
							trip_ids.push trip.trip_id  if trip
							cb()
					), (e) ->
						cb null, "trips"
				else
					cb new Error("Invalid agency_key or route_id"), "trips"


	getStopTimes = (cb) ->
		StopTimesFinderByTripId = (trip_id, cb) ->
			StopTime.find(
				{ agency_key: agency_key, trip_id: trip_id },
				null,
				sort: "stop_sequence",
				(e, stopTimes) ->

					#compare to longest trip to see if trip length is longest
					longestTrip = stopTimes  if stopTimes.length and stopTimes.length > longestTrip.length
					cb()
			)

		async.forEach trip_ids, StopTimesFinderByTripId, (e) ->
			cb null, "times"


	getStops = (cb) ->

		StopFinders = (stopTime, cb) ->
			Stop.findOne { agency_key: agency_key, stop_id: stopTime.stop_id }, (e, stop) ->
				stops.push stop
				cb()

		async.forEachSeries longestTrip, StopFinders, (e) ->
			if e
				cb new Error("No stops found"), "stops"
			else
				cb null, "stops"


getTimesByStop = (agency_key, route_id, stop_id, direction_id, cb) ->
	numOfTimes = 1000 #this is dumb but no calls to getTimesByStop() seem
	#to want to give it a numOfTimes argument. 1000 is probably at least 10x
	#more times than will be returned.

	#gets routes for one agency
	if _.isFunction(direction_id)
		cb = direction_id
		direction_id = null #default is ~ 1/4 mile
	today = new Date()
	service_ids = []
	trip_ids = []
	times = []
	today = new Date()
	service_ids = []
	trip_ids = []
	times = []
	d = new Date()
	utc = d.getTime() + (d.getTimezoneOffset() * 60000)
	now = new Date(utc + (3600000 * (-4)))
	nowHour = now.getHours()
	nowMinute = now.getMinutes()
	nowSecond = now.getSeconds()
	nowDispHour = (if (nowHour < 10) then "0" + nowHour else nowHour)
	nowDispMinute = (if (nowMinute < 10) then "0" + nowMinute else nowMinute)
	nowDispSecond = (if (nowSecond < 10) then "0" + nowSecond else nowSecond)
	currentTime = nowDispHour + ":" + nowDispMinute + ":" + nowDispSecond

	#Find service_id that matches todays date
	async.series [
		checkFields
		findServices
		findTrips
		findTimes
	], (e, results) ->
		if e
			cb e, null
		else
			cb e, times
		return


	checkFields = (cb) ->
		unless agency_key
			cb new Error("No agency_key specified"), "fields"
		else unless stop_id
			cb new Error("No stop_id specified"), "fields"
		else unless route_id
			cb new Error("No route_id specified"), "fields"
		else
			cb null, "fields"
		return



	findServices = (cb) ->
		query = agency_key: agency_key
		todayFormatted = utils.formatDay(today)

		#build query
		query[utils.getDayName(today).toLowerCase()] = 1
		Calendar.find(query).where("start_date").lte(todayFormatted).where("end_date").gte(todayFormatted).exec (e, services) ->
			if services.length
				services.forEach (service) ->
					service_ids.push service.service_id
					return

				cb null, "services"
			else
				cb new Error("No Service for this date"), "services"
			return

		return


	findTrips = (cb) ->
		query =
			agency_key: agency_key
			route_id: route_id


		if (direction_id == 0) || (direction_id == 1)
			query.direction_id = direction_id;
		else
			query["$or"] = [{direction_id:0},{direction_id:1}]


		Trip
		.find(query)
		.where('service_id').in(service_ids)
		.exec( (e, trips) ->
			if (trips.length)
				trips.forEach (trip) ->
					trip_ids.push(trip.trip_id)

				cb(null, 'trips')
			else
				cb(new Error('No trips for this date'), 'trips')
		)

getStopsByDistance = (lat, lon, radius, cb) ->

	#gets all stops within a radius
	if _.isFunction(radius)
		cb = radius
		radius = 1 #default is 1 mile
	lat = parseFloat(lat)
	lon = parseFloat(lon)
	radiusInDegrees = Math.round(radius / 69 * 100000) / 100000
	Stop.where("loc").near(lon, lat).maxDistance(radiusInDegrees).exec (e, results) ->
		cb e, results

getTimesByStop = (agency_key, route_id, stop_id, direction_id, cb) ->
	numOfTimes = 1000 #this is dumb but no calls to getTimesByStop() seem
	#to want to give it a numOfTimes argument. 1000 is probably at least 10x
	#more times than will be returned.

	#gets routes for one agency
	if _.isFunction(direction_id)
		cb = direction_id
		direction_id = null #default is ~ 1/4 mile

	today = new Date()

	service_ids = []
	trip_ids = []
	times = []
	today = new Date()
	service_ids = []
	trip_ids = []
	times = []

	d = new Date()
	utc = d.getTime() + (d.getTimezoneOffset() * 60000)
	now = new Date(utc + (3600000 * (-4)))
	nowHour = now.getHours()
	nowMinute = now.getMinutes()
	nowSecond = now.getSeconds()
	nowDispHour = (if (nowHour < 10) then "0" + nowHour else nowHour)
	nowDispMinute = (if (nowMinute < 10) then "0" + nowMinute else nowMinute)
	nowDispSecond = (if (nowSecond < 10) then "0" + nowSecond else nowSecond)
	currentTime = nowDispHour + ":" + nowDispMinute + ":" + nowDispSecond

	#Find service_id that matches todays date
	async.series [
		checkFields
		findServices
		findTrips
		findTimes
	], (e, results) ->
		if e
			cb e, null
		else
			cb e, times


	checkFields = (cb) ->
		unless agency_key
			cb new Error("No agency_key specified"), "fields"
		else unless stop_id
			cb new Error("No stop_id specified"), "fields"
		else unless route_id
			cb new Error("No route_id specified"), "fields"
		else
			cb null, "fields"
		return

	findServices = (cb) ->
		query = agency_key: agency_key
		todayFormatted = utils.formatDay(today)

		#build query
		query[utils.getDayName(today).toLowerCase()] = 1
		Calendar.find(query).where("start_date").lte(todayFormatted).where("end_date").gte(todayFormatted).exec (e, services) ->
			if services.length
				services.forEach (service) ->
					service_ids.push service.service_id

				cb null, "services"
			else
				cb new Error("No Service for this date"), "services"


	findTrips = (cb) ->
		query =
			agency_key: agency_key
			route_id: route_id


		if (direction_id == 0) || (direction_id == 1)
			query.direction_id = direction_id;
		else
			query["$or"] = [ {direction_id:0}, {direction_id:1} ]

		Trip
			.find(query)
			.where('service_id').in(service_ids)
			.exec((e, trips) ->
				if(trips.length)
					trips.forEach (trip) ->
						trip_ids.push(trip.trip_id);

					cb(null, 'trips')
				else
					cb(new Error('No trips for this date'), 'trips');
			)

	findTimes = (cb) ->
		query = {
			agency_key: agency_key,
			stop_id: stop_id
		}

		StopTime
			.find(query)
			.where('trip_id').in(trip_ids)
			.sort('departure_time') #asc has been removed in favor of sort as of mongoose 3.x
			.limit(numOfTimes)
			.exec((e, stopTimes) ->
				if stopTimes.length
					stopTimes.forEach (stopTime) ->
						times.push(stopTime.departure_time)

					cb(null, 'times')
				else
					cb(new Error('No times available for this stop on this date'), 'times')
			)


findBothDirectionNames = (agency_key, route_id, cb) ->
	findDirectionName = (agency_key, route_id, direction_id, cb) ->
		query =
			agency_key: agency_key
			route_id: route_id
			direction_id: direction_id

		Trip.find(query).limit(1).run (e, trips) ->
			cb trips[0].trip_headsign


	findDirectionName agency_key, route_id, 0, (northData) ->
		findDirectionName agency_key, route_id, 1, (southData) ->
			ret =
				northData: northData
				southData: southData

			cb ret


########################################################################################
### Exports
########################################################################################

module.exports =
	agencies: agencies
	getRoutesByAgency: getRoutesByAgency
	getAgenciesByDistance: getAgenciesByDistance
	getRoutesByDistance: getRoutesByDistance
	getTimesByStop: getTimesByStop
	getStopsByRoute: getStopsByRoute
	getStopsByDistance: getStopsByDistance
	findBothDirectionNames: findBothDirectionNames