########################################################################################
### Modules
### #####################################################################################

async = require 'async'
Promise = require 'bluebird'

MongoClient = require('mongodb').MongoClient

config = require '../conf/config'
gtfs = require '../conf/gtfs'
logger = require '../log/logger'

CsvLineToObjectStream = require '../stream/CsvLineToObjectStream'


########################################################################################
### variables
########################################################################################

dbPromise = Promise.promisify(MongoClient.connect)("mongodb://#{config.mongo.hostname}:#{config.mongo.port}/#{config.mongo.dbname}")
db = undefined


########################################################################################
### Functions
########################################################################################

performBatchInsert = (db, model, records, callback) ->
	modelCollection = db.collection(model)
	batch = modelCollection.initializeUnorderedBulkOp()

	records.line.forEach (record) ->
		batch.insert record

	batch.execute callback

makeNodeResolver = (deferred) ->
	(err, result) ->
		if err
			deferred.reject(err)
		else
			deferred.fulfill(result.nInserted)


########################################################################################
### Module
########################################################################################

importLines = (agency, model, records) ->
	deferred = Promise.defer()

	#	mmodel = gtfs.models[model]

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
	#
	#	mrecords = records.line.map (record) ->
	#		new mmodel(record)

	if records.line.length == 0
		deferred.fulfill(0)
	else

		if db
			performBatchInsert db, model, records, makeNodeResolver(deferred)
		else
			dbPromise
			.then (pDb) ->
				db = pDb
				performBatchInsert db, model, records, makeNodeResolver(deferred)
			.catch (err) ->
					deferred.reject(err)

	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	importLines: importLines