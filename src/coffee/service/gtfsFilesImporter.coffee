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


########################################################################################
### Functions
########################################################################################

importGTFSFiles = (agency, GTFSFiles, downloadDir) ->

	job =
		uuid: new Chance().hash({ length: 4, casing: 'upper' })

	logger.info "[JOB:#{job.uuid}][GTFS_IMPORT] Importing GTFS files ..."

	amqpClient.publishMessage "JOB_START", { job: job }

	Promise.all(
		GTFSFiles.map (GTFSFile) ->
			gtfsFileImporter.importGTFSFile(job, agency, GTFSFile, downloadDir)
	)


########################################################################################
### Exports
########################################################################################

module.exports =
	importGTFSFiles: importGTFSFiles