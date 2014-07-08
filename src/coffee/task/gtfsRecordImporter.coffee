########################################################################################
### Modules
### #####################################################################################

Promise = require 'bluebird'

MongoClient = require('mongodb').MongoClient

config = require '../conf/config'
logger = require '../log/logger'


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

	records.forEach (record) ->
		batch.insert record

	batch.execute callback

makeNodeResolver = (agency, deferred) ->
	(err, result) ->
		if err
			deferred.reject err
		else
			deferred.fulfill {
				agency: agency
				inserted: result.nInserted
				errors: result.getWriteErrorCount()
			}


########################################################################################
### Module
########################################################################################

importLines = (agency, model, records) ->
	deferred = Promise.defer()


	records.forEach (record) ->
		record.agency_key = agency.key
		if record.stop_sequence
			record.stop_sequence = parseInt(record.stop_sequence, 10)
		if record.direction_id
			record.direction_id = parseInt(record.direction_id, 10)

		if record.stop_lat and record.stop_lon
			record.loc = [ parseFloat(record.stop_lon), parseFloat(record.stop_lat) ]
			agency.bounds = { sw: [], ne: [] }
			agency.bounds.sw[0] = record.loc[0]  if agency.bounds.sw[0] > record.loc[0] or not agency.bounds.sw[0]
			agency.bounds.ne[0] = record.loc[0]  if agency.bounds.ne[0] < record.loc[0] or not agency.bounds.ne[0]
			agency.bounds.sw[1] = record.loc[1]  if agency.bounds.sw[1] > record.loc[1] or not agency.bounds.sw[1]
			agency.bounds.ne[1] = record.loc[1]  if agency.bounds.ne[1] < record.loc[1] or not agency.bounds.ne[1]


	if records.length == 0
		deferred.fulfill 0
	else

		if db
			performBatchInsert db, model, records, makeNodeResolver(agency, deferred)
		else
			dbPromise
			.then (pDb) ->
				db = pDb
				performBatchInsert db, model, records, makeNodeResolver(agency, deferred)
			.catch (err) ->
				deferred.reject err

	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	importLines: importLines