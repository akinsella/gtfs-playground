########################################################################################
### Modules
########################################################################################

config = require '../conf/config'
gtfs = require '../conf/gtfs'
logger = require '../log/logger'
gtfsImportService = require '../service/gtfsImportService'



########################################################################################
### Functions
########################################################################################

importData = (req, res) ->
	gtfsImportService.importData(gtfs.agencies, gtfs.files, config.downloads.directory)
	.then (agencyCount) ->
		logger.info "[GTFS][IMPORT] Imported #{agencyCount} agencies data"
	.catch (err) ->
		logger.info "[GTFS][IMPORT] Failed with error: #{err.message} - #{err.stack}"
		res.send 500, err.message



########################################################################################
### Exports
########################################################################################

module.exports =
	importData: importData