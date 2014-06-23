########################################################################################
### Modules
########################################################################################

Promise = require 'bluebird'

Agency = Promise.promisifyAll(require('../model/agency'))



########################################################################################
### Functions
########################################################################################

updateLastUpdateDate = (agency) ->
	query = { agency_key: agency.key }
	updateData = { $set: { date_last_updated: Date.now() } }
	Agency.update(query, updateData)


updateAgencyCenter = (agency) ->
	query = { agency_key: agency.key }
	updateData = { $set: {
		agency_bounds: agency.bounds,
		agency_center: [
			(agency.bounds.ne[0] - agency.bounds.sw[0]) / 2 + agency.bounds.sw[0]
			(agency.bounds.ne[1] - agency.bounds.sw[1]) / 2 + agency.bounds.sw[1]
		] }
	}
	Agency.update(query, updateData)



########################################################################################
### Exports
########################################################################################

module.exports =
	updateLastUpdateDate: updateLastUpdateDate
	updateAgencyCenter: updateAgencyCenter