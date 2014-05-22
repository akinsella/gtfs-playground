########################################################################################
### Modules
########################################################################################

Q = require 'q'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

logger = require '../log/logger'

archiveDownloader = require './archiveDownloader'
mongoCollectionsRemover = require './mongoCollectionsRemover'
agencyService = require './agencyService'
gtfsFilesImporter = require './gtfsFilesImporter'



########################################################################################
### Init
########################################################################################

importAgency = (agency, GTFSFiles, downloadDir) ->

	logger.info "Starting '#{agency.key}' agency"

	Q('import-gtfs-agency')
	.then () ->
		removeDir(downloadDir)
	.then () ->
		createDir(downloadDir)
	.then () ->
		archiveDownloader.downloadArchive(agency.url, downloadDir)
	.then () ->
		Q.all(
			GTFSFiles.map (GTFSFile) ->
				mongoCollectionsRemover.removeCollectionByModel(GTFSFile.collection, agency.key)
		)
	.then () ->
		gtfsFilesImporter.importGTFSFiles(agency, GTFSFiles, downloadDir)
	.then () ->
		agencyService.updateAgencyCenter(agency)
	.then () ->
		agencyService.updateLastUpdateDate(agency.key)
	.then () ->
		removeDir(downloadDir)
	.then () ->
		logger.info "#{agency.key}: Completed"


removeDir = (dir) ->
	deferred = Q.defer()
	rimraf dir, deferred.makeNodeResolver()
	deferred.promise

createDir = (dir) ->
	deferred = Q.defer()
	mkdirp dir, deferred.makeNodeResolver()
	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	importAgency: importAgency