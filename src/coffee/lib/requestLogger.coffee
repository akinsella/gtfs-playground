########################################################################################
### Modules
########################################################################################

logger = require 'winston'


########################################################################################
### Functions
########################################################################################

middleware = () ->
	(req, res, next) ->
			logger.info "---------------------------------------------------------"
			logger.info "Http Request - Url: ", req.url
			logger.info "Http Request - Query: ", req.query
			logger.info "Http Request - Method: ", req.method
			logger.info "Http Request - Headers: ", req.headers
			logger.info "Http Request - Body: ", req.body
			logger.info "Http Request - Raw Body: ", req.rawBody
			logger.info "---------------------------------------------------------"

			next()


########################################################################################
### Exports
########################################################################################

module.exports = middleware