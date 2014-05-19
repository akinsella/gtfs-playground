########################################################################################
### Modules
########################################################################################

fs = require 'fs'
request = require 'request'
unzip = require 'unzip'
Q = require 'q'

config = require '../conf/config'
logger = require '../log/logger'



########################################################################################
### Functions
########################################################################################

downloadArchive = (archiveURL, downloadDir) ->
	deferred = Q.defer()

	logger.info "Downloading file with URL: '#{archiveURL}'"
	processFile = (err, response, body) ->
		if response and response.statusCode isnt 200
			deferred.reject(new Error("Couldn't download files"))
		else
			logger.info "File with URL: '#{archiveURL}' downloaded"
			fs.createReadStream("#{downloadDir}/latest.zip")
			.pipe(unzip.Extract(path: downloadDir).on("close", deferred.makeNodeResolver()))
			.on "error", (err) ->
				logger.info "[ERROR][Name:#{err.name}] #{err.message}"
				deferred.reject(err)

	request(archiveURL, processFile).pipe(fs.createWriteStream("#{downloadDir}/latest.zip"))

	deferred.promise


########################################################################################
### Exports
########################################################################################

module.exports =
	downloadFiles: downloadArchive