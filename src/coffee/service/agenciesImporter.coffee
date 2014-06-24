
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

	taskQueue = createTaskQueue deferred, taskProcessor, () ->
		deferred.fulfill()
	, (err) ->
		if err
			deferred.reject err

	agencies.forEach (agency) ->
		if deferred.promise.isPending()
			taskQueue.enqueueAgency(agency)

	deferred.promise


createTaskQueue = (deferred, taskProcessor, drainCb, pushCb) ->

	taskQueue = async.queue(taskProcessor, 1)

	taskQueue.enqueueAgency = (agency) ->
		taskQueue.push { agency: agency }, pushCb

	taskQueue.drain = drainCb

	taskQueue


#######################################################################################
### Exports
########################################################################################

module.exports =
	importAgencies: importAgencies