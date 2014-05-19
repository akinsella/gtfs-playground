########################################################################################
### Modules
########################################################################################

Q = require 'q'

logger = require '../log/logger'

gtfsFileImporter = require './gtfsFileImporter'

########################################################################################
### Functions
########################################################################################

importGTFSFiles = (agency, GTFSFiles, downloadDir) ->

	logger.info "Importing GTFS files ..."

	Q.all(
		GTFSFiles.map (GTFSFile) ->
			gtfsFileImporter.importGTFSFile(agency, GTFSFile, downloadDir)
	)


########################################################################################
### Exports
########################################################################################

module.exports =
	importGTFSFiles: importGTFSFiles