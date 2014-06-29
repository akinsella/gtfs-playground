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

SplitLinesToObjectStream = (GTFSFile, agency, options) ->
	options or options = {}

	transformOptions =
		objectMode: true

	if options.highWaterMark
		transformOptions.highWaterMark = options.highWaterMark

	stream.Transform.call(this, transformOptions)
	@GTFSFile = GTFSFile
	@agency = agency
	@index = 0


util.inherits(SplitLinesToObjectStream, stream.Transform)


SplitLinesToObjectStream.prototype._transform = (chunk, encoding, callback) ->
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