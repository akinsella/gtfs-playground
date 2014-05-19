########################################################################################
### Modules
########################################################################################

Q = require 'q'

logger = require '../log/logger'



########################################################################################
### Functions
########################################################################################

removeCollectionByModel = (model, agencyKey) ->

	logger.info "Removing database collection: '#{model.modelName}' ..."
	Q.when(model.remove({ agency_key: agencyKey }).exec())


########################################################################################
### Exports
########################################################################################

module.exports =
	removeCollectionByModel: removeCollectionByModel