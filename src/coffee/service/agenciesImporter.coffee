
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

	taskQueue = Promise.promisify(createTaskQueue)(deferred, taskProcessor)

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