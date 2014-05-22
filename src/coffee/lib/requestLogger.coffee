########################################################################################
### Modules
########################################################################################

logger = require 'winston'
util = require 'util'

########################################################################################
### Functions
########################################################################################

middleware = () ->
	(req, res, next) ->
			logger.info  """---------------------------------------------------------
							Http Request - Pid process: [#{process.pid}]
							Http Request - Url: #{req.url}
							Http Request - Query: #{util.inspect(req.query)}
							Http Request - Method: #{req.method}
							Http Request - Headers: #{util.inspect(req.headers)}
							Http Request - Body: #{util.inspect(req.body)}
							Http Request - Raw Body: #{req.rawBody}
							---------------------------------------------------------"""

			next()


########################################################################################
### Exports
########################################################################################

module.exports = middleware