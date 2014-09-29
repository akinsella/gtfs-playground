########################################################################################
### Modules
########################################################################################

logger = require '../log/logger'
gtfs = require '../conf/gtfs'

GtfsRecordsImportTask = require '../task/GtfsRecordsImportTask'

########################################################################################
### Class
########################################################################################

class JobStartConsumer

	constructor: (@amqpClient) ->


	handleMessage: (channel, message) =>
		logger.info "[JOB_START_CONSUMER][MESSAGE] Received job start event for job with uuid: '#{message.job.uuid}'"
		for gtfsFile in gtfs.files
			queueName = "#{gtfsFile.fileNameBase}_#{message.job.uuid}".toUpperCase().replace /[-]/g, '_'

			logger.debug "Creating subscribtion for queue: #{queueName}"
			@amqpClient.subscribeQueue queueName, { ack: true, prefetchCount: 1 }, new GtfsRecordsImportTask(gtfsFile.fileNameBase)


########################################################################################
### Modules
########################################################################################

module.exports = JobStartConsumer