########################################################################################
### Modules
########################################################################################

Promise = require 'bluebird'
Chance = require 'chance'

logger = require '../log/logger'
amqp = require '../lib/amqp'

gtfsFileImporter = require './gtfsFileImporter'
JobStartConsumer = require './JobStartConsumer'


########################################################################################
### Job stuff
########################################################################################

amqpClient = amqp.createClient "GTFS_FILES_IMPORTER"


amqpClient.subscribeQueue "JOB_START", new JobStartConsumer(amqpClient)


########################################################################################
### Functions
########################################################################################

importGTFSFiles = (agency, GTFSFiles, downloadDir) ->

	job =
		uuid: new Chance().hash({ length: 4, casing: 'upper' })

	logger.info "[#{process.pid}][JOB:#{job.uuid}][GTFS_IMPORT] Importing GTFS files ..."

	amqpClient.publishJSON "JOB_START", job: job

	Promise.all(
		GTFSFiles.map (GTFSFile) ->
			gtfsFileImporter.importGTFSFile(job, agency, GTFSFile, downloadDir)
	)


########################################################################################
### Exports
########################################################################################

module.exports =
	importGTFSFiles: importGTFSFiles