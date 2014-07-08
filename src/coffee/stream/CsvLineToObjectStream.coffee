########################################################################################
### Modules
########################################################################################

util = require 'util'
stream = require 'stream'

config = require '../conf/config'
logger = require '../log/logger'


########################################################################################
### Stream
########################################################################################

class CsvLineToObjectStream extends stream.Transform

	constructor: (@GTFSFile, @agency_key, @agency_bounds, @options) ->
		@options or @options = {}

		transformOptions =
			objectMode: true

		if @options.highWaterMark
			transformOptions.highWaterMark = @options.highWaterMark

		super(transformOptions)


	_transform: (chunk, encoding, callback) ->

		logger.info "[CL2O][#{process.pid}] Index: #{@index}" if @index % 10000 == 0
		this.push(chunk)

		callback()



########################################################################################
### Exports
########################################################################################

module.exports = CsvLineToObjectStream