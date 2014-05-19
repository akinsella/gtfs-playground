########################################################################################
### Modules
########################################################################################

fs = require 'fs'
request = require 'request'
unzip = require 'unzip'

config = require '../conf/config'
logger = require '../log/logger'



########################################################################################
### Functions
########################################################################################

downloadArchive = (archiveURL, downloadDir, cb) ->

	logger.info "Downloading file with URL: '#{archiveURL}'"
	processFile = (err, response, body) ->
		if response and response.statusCode isnt 200
			cb new Error("Couldn't download files")
		else
			logger.info "File with URL: '#{archiveURL}' downloaded"
			fs.createReadStream("#{downloadDir}/latest.zip")
			.pipe(unzip.Extract(path: downloadDir).on("close", cb))
			.on "error", (err) ->
				logger.info "[ERROR][Name:#{err.name}] #{err.message}"
				throw err

	request(archiveURL, processFile).pipe(fs.createWriteStream("#{downloadDir}/latest.zip"))



########################################################################################
### Exports
########################################################################################

module.exports =
	downloadFiles: downloadArchive