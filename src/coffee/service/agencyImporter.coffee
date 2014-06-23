########################################################################################
### Modules
########################################################################################

Promise = require 'bluebird'
mkdirp = Promise.promisify(require('mkdirp'))
rimraf = Promise.promisify(require('rimraf'))

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

	Promise.cast('import-gtfs-agency')
	.then () ->
		rimraf(downloadDir)
	.then () ->
		mkdirp(downloadDir)
	.then () ->
		archiveDownloader.downloadArchive(agency.url, downloadDir)
	.then () ->
		Promise.all(
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
		rimraf(downloadDir)
	.then () ->
		logger.info "#{agency.key}: Completed"



########################################################################################
### Exports
########################################################################################

module.exports =
	importAgency: importAgency