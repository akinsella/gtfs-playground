########################################################################################
### Modules
########################################################################################
_ = require 'underscore'
util = require 'util'

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
			key: item
			url: "http://www.gtfs-data-exchange.com/agency/#{item}/latest.zip"
	else
		agency = _.extend({}, item) #FIXME: Should copy object

	if not agency.key or not agency.url
		throw new Error("No URL or Agency Key provided.")

	agency



########################################################################################
### exports
########################################################################################

module.exports =
	importData: importData