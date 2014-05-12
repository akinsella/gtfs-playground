########################################################################################
### Modules
########################################################################################

logger = require 'winston'


########################################################################################
### Functions
########################################################################################

middleware = () ->
	(req, res, next) ->
			logger.info  """---------------------------------------------------------
							Http Request - Pid process: [#{process.pid}]
							Http Request - Url: #{req.url}
							Http Request - Query: #{req.query}
							Http Request - Method: #{req.method}
							Http Request - Headers: #{req.headers}
							Http Request - Body: #{req.body}
							Http Request - Raw Body: #{req.rawBody}
							---------------------------------------------------------"""

			next()


########################################################################################
### Exports
########################################################################################

module.exports = middleware