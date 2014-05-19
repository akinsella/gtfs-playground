########################################################################################
### Modules
########################################################################################

config = require '../conf/config'
logger = require '../log/logger'

GtfsRecordsImportTask = require '../task/GtfsRecordsImportTask'

agenciesImporter = require './agenciesImporter'



########################################################################################
### Import
########################################################################################

importData = (agencyItems, GTFSFiles, downloadDir) ->

	logger.info "Initializing GTFSImportService on worker with pid: #{process.pid}"

	agencies = agencyItems.map(agencyFromItem)

	agenciesImporter.importAgencies(agencies, GTFSFiles, downloadDir)


agencyFromItem = (item) ->
	if typeof (item) is "string"
		agency =
			agency_key: item
			agency_url: "http://www.gtfs-data-exchange.com/agency/#{item}/latest.zip"
	else
		agency =
			agency_key: item.agency_key
			agency_url: item.url

	if not agency.agency_key or not agency.agency_url
		throw new Error("No URL or Agency Key provided.")



########################################################################################
### exports
########################################################################################

module.exports =
	importData: importData