########################################################################################
### Modules
########################################################################################

gtfsImportService = require '../service/gtfsImportService'

########################################################################################
### Functions
########################################################################################

importData = (req, res) ->
	gtfsImportService.importData()
	.then (agencyCount) ->
		logger.info "[GTFS][IMPORT] Imported #{agencyCount} agencies data"
	.fail (err) ->
		logger.info "[GTFS][IMPORT] Failed with error: #{err.message}"
		res.send 500, err.message



########################################################################################
### Exports
########################################################################################

module.exports =
	importData: importData