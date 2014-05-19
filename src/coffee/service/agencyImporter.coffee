########################################################################################
### Modules
########################################################################################

request = require 'request'
exec = require('child_process').exec
fs = require 'fs'
path = require 'path'
csv = require 'csv-streamify'
async = require 'async'
Q = require 'q'
util = require 'util'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

mongo = require '../lib/mongo'
config = require '../conf/config'
logger = require '../log/logger'

archiveDownloader = require './archiveDownloader'
mongoCollectionsRemover = require './mongoCollectionsRemover'
agencyService = require './agencyService'
gtfsFilesImporter = require './gtfsFilesImporter'

Agency = require '../model/agency'



########################################################################################
### Init
########################################################################################

importAgency = (agency, GTFSFiles, downloadDir) ->

	agencyKey = agency.key
	agencyBounds = { sw: [], ne: [] } # FIXME

	logger.info "Starting '#{agencyKey}' agency"

	Q.nfCall(rimraf, downloadDir)
	.then () ->
		Q.nfCall(mkdirp, downloadDir)
	.then () ->
		archiveDownloader.downloadArchive(agency.url, downloadDir)
	.then () ->
		Q.all(
			GTFSFiles.map (GTFSFile) ->
				mongoCollectionsRemover.removeCollections(GTFSFile.collection, agency.key)
		)
	.then () ->
		gtfsFilesImporter.importGTFSFiles(agency, GTFSFiles, downloadDir)
	.then () ->
		logger.info "#{agencyKey}:  Post Processing data"
		Q.nfCall(async.series, [ agencyCenter, longestTrip, updatedDate ])
	.then () ->
		agencyService.updateAgencyCenter(agency.key, agencyBounds)
#	.then () ->
#		longestTrip = (cb) ->
#			###
#				Trips.find({agencyKey: agencyKey}).for.toArray (e, trips) ->
#					async.each trips, (trip, cb) ->
#						mongo.client.collection('stoptimes', (e, collection) ->
#
#						logger.info(trip);
#						cb()
#			###
#			cb()
	.then () ->
		agencyService.updateLastUpdateDate(agency.key)
	.then () ->
		Q.nfCall(rimraf, downloadDir)
	.then () ->
		logger.info "#{agencyKey}: Completed"




########################################################################################
### Exports
########################################################################################

module.exports =
	importAgency: importAgency