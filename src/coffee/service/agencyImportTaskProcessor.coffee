########################################################################################
### Modules
########################################################################################

_ = require 'underscore'
config = require '../conf/config'
logger = require '../log/logger'

agencyImporter = require './agencyImporter'


########################################################################################
### Init
########################################################################################

createTaskProcessor = (GTFSFiles, downloadDir) ->

	(task, cb) ->

		agency = _.extend({ bounds: { sw: [], ne: [] }}, task.agency)

		agencyImporter.importAgency(agency, GTFSFiles, downloadDir)
		.then((data) -> cb(data))
		.catch((err) -> cb(err))



########################################################################################
### Exports
########################################################################################

module.exports =
	createTaskProcessor: createTaskProcessor