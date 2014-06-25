########################################################################################
### Modules
########################################################################################

Promise = require 'bluebird'
logger = require '../log/logger'



########################################################################################
### Functions
########################################################################################

removeCollectionByModel = (model, agencyKey) ->

	logger.info "Removing database collection: '#{model.modelName}' ..."
	Promise.promisify(model.remove, model)({ agency_key: agencyKey })


########################################################################################
### Exports
########################################################################################

module.exports =
	removeCollectionByModel: removeCollectionByModel