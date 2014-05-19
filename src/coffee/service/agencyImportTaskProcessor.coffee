########################################################################################
### Modules
########################################################################################

config = require '../conf/config'
logger = require '../log/logger'

agencyImporter = require './agencyImporter'


########################################################################################
### Init
########################################################################################

createTaskProcessor = (GTFSFiles, downloadDir) ->

	(task, cb) ->

		agency = { key: task.agency_key, url: task.agency_url }

		agencyImporter.importAgency(agency, GTFSFiles, downloadDir)
		.then((data) -> cb(data))
		.fail((err) -> cb(err))



########################################################################################
### Exports
########################################################################################

module.exports =
	createTaskProcessor: createTaskProcessor