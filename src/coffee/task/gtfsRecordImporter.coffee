########################################################################################
### Modules
########################################################################################

async = require 'async'
Promise = require 'bluebird'

config = require '../conf/config'
gtfs = require '../conf/gtfs'
logger = require '../log/logger'

Stream = require 'stream'

csv = require 'csv-streamify'
CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'


class StringStream extends Stream.Readable
	constructor: (@str) ->
		super()

	_read: (size) ->
		@push new Buffer(@str).toString('utf-8')
		@push null


########################################################################################
### Class
########################################################################################

importLines = (agency, model, records) ->
	deferred = Promise.defer()

	mmodel = gtfs.models[model]

	#	agencyKey = agency.key
	#	agencyBounds = agency.bounds

#	records.line.forEach (record) ->
#		record.agency_key = agency.key
#		if record.stop_sequence
#			record.stop_sequence = parseInt(record.stop_sequence, 10)
#		if record.direction_id
#			record.direction_id = parseInt(record.direction_id, 10)

#		if record.stop_lat and record.stop_lon
#			record.loc = [ parseFloat(record.stop_lon), parseFloat(record.stop_lat) ]
#			agencyBounds.sw[0] = record.loc[0]  if agencyBounds.sw[0] > record.loc[0] or not agencyBounds.sw[0]
#			agencyBounds.ne[0] = record.loc[0]  if agencyBounds.ne[0] < record.loc[0] or not agencyBounds.ne[0]
#			agencyBounds.sw[1] = record.loc[1]  if agencyBounds.sw[1] > record.loc[1] or not agencyBounds.sw[1]
#			agencyBounds.ne[1] = record.loc[1]  if agencyBounds.ne[1] < record.loc[1] or not agencyBounds.ne[1]

	mrecords = records.line.map (record) ->
		new mmodel(record)

	mmodel.create mrecords, (err) ->
			if err
				deferred.reject(err)

	.on 'finish', (err, data) ->
		if err
			deferred.reject(err)
		else
			deferred.fulfill(data)

	deferred.promise



########################################################################################
### Exports
########################################################################################

module.exports =
	importLines: importLines