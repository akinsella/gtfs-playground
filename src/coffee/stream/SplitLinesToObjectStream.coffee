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

class SplitLinesToObjectStream extends stream.Transform

	constructor: (@GTFSFile, @agency, @options) ->
		@options or @options = {}
		@index = 0

		transformOptions =
			objectMode: true

		if options.highWaterMark
			transformOptions.highWaterMark = @options.highWaterMark

		super(transformOptions)


	_transform: (chunk, encoding, callback) ->
		@index++

		logger.info "[CL2O][#{process.pid}] Index: #{@index}"  if @index % 10000 == 0

		this.push(
			model: @GTFSFile.collection.modelName
			index: @index
			line: chunk
			agency:
				key: @agency.key
				bounds: { sw: [], sw: [] }
		)

		callback()



########################################################################################
### Exports
########################################################################################

module.exports = SplitLinesToObjectStream