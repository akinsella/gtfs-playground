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

	model = gtfs.models[model]

	recordsStream = new StringStream(records)

	csvStream = csv({ objectMode: true, newline:'\n' })

	cl2oStream = new CsvLineToObjectStream( model, agency.key, { sw: [], ne: [] })

	recordsStream
	.pipe(csvStream)
	.pipe(cl2oStream)
	.on 'data', (message) ->

		agencyKey = agency.key
		agencyBounds = agency.bounds

		line = message.line

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

		model.create new model(line), (err) ->
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