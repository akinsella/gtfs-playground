########################################################################################
### Modules
########################################################################################

fs = require 'fs'
request = require 'request'
unzip = require 'unzip'
Q = require 'q'
moment = require 'moment'

config = require '../conf/config'
logger = require '../log/logger'



########################################################################################
### Functions
########################################################################################

downloadArchive = (archiveURL, downloadDir) ->
	deferred = Q.defer()

	start = moment()

	logger.info "Downloading file with URL: '#{archiveURL}'"

	request(archiveURL)
	.on "end", () ->
		duration = moment.duration(moment().diff(start)).asMilliseconds()
		logger.info "Downloaded file ended in #{duration} ms"
		start = moment()
	.pipe(unzip.Extract(path: downloadDir))
	.on "close", (err) ->
		duration = moment.duration(moment().diff(start)).asMilliseconds()
		logger.info "Unzip file ended in #{duration} ms"
		if err
			deferred.reject err
		else
			deferred.resolve()
	.on "error", (err) ->
		logger.info "[ERROR][Name:#{err.name}] #{err.message}"
		deferred.reject(err)

	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	downloadArchive: downloadArchive