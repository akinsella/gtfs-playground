
########################################################################################
### Modules
########################################################################################

async = require 'async'
Q = require 'q'

config = require '../conf/config'
logger = require '../log/logger'

agencyImportTaskProcessor = require './agencyImportTaskProcessor'



########################################################################################
### Functions
########################################################################################

importAgencies = (agencies, GTFSFiles, downloadDir) ->

	deferred = Q.defer()

	taskProcessor = agencyImportTaskProcessor.createTaskProcessor(GTFSFiles, downloadDir)

	taskQueue = createTaskQueue deferred, taskProcessor, deferred.makeNodeResolver()

	agencies.forEach (agency) ->
		taskQueue.enqueueAgency(agency)

	deferred.promise


createTaskQueue = (deferred, taskProcessor, cb) ->

	taskQueue = async.queue(taskProcessor, 1)

	taskQueue.drain = cb

	taskQueue


#######################################################################################
### Exports
########################################################################################

module.exports =
	importAgencies: importAgencies