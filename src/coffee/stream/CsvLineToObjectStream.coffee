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

CsvLineToObjectStream = (GTFSFile, agency_key, agency_bounds) ->
	stream.Transform.call(this, { objectMode : true })
	@GTFSFile = GTFSFile
	@agency_key = agency_key
	@agency_bounds = agency_bounds
	@index = 0

util.inherits(CsvLineToObjectStream, stream.Transform)

CsvLineToObjectStream.prototype._transform = (chunk, encoding, callback) ->
	@index++

	logger.info "Index: #{@index}"  if @index % 10000 == 0

	this.push(
		model: @GTFSFile.collection.modelName
		index: @index
		line: chunk
		agency:
			key: @agency_key
			bounds: @agency_bounds
	)

	callback()



########################################################################################
### Exports
########################################################################################

module.exports = CsvLineToObjectStream