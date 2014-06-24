
########################################################################################
### Modules
########################################################################################

async = require 'async'
Promise = require 'bluebird'

config = require '../conf/config'
logger = require '../log/logger'

agencyImportTaskProcessor = require './agencyImportTaskProcessor'



########################################################################################
### Functions
########################################################################################

importAgencies = (agencies, GTFSFiles, downloadDir) ->

	deferred = Promise.pending()

	taskProcessor = agencyImportTaskProcessor.createTaskProcessor(GTFSFiles, downloadDir)

	taskQueue = createTaskQueue deferred, taskProcessor, (err, result) ->
		if err
			deferred.reject err
		else
			deferred.fulfill result

	agencies.forEach (agency) ->
		taskQueue.enqueueAgency(agency)

	deferred.promise


createTaskQueue = (deferred, taskProcessor, cb) ->

	taskQueue = async.queue(taskProcessor, 1)

	taskQueue.enqueueAgency = (agency) ->
		taskQueue.push { agency: agency }

	taskQueue.drain = cb

	taskQueue


#######################################################################################
### Exports
########################################################################################

module.exports =
	importAgencies: importAgencies