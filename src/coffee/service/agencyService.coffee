########################################################################################
### Modules
########################################################################################

Q = require 'q'

Agency = require '../model/agency'



########################################################################################
### Functions
########################################################################################

updateLastUpdateDate = (agencyKey) ->
	query = { agency_key: agencyKey }
	updateData = { $set: { date_last_updated: Date.now() } }
	Q.when(Agency.update(query, updateData).exec())


updateAgencyCenter = (agencyKey, agencyBounds) ->
	query = { agency_key: agencyKey }
	updateData = { $set: {
		agency_bounds: agencyBounds,
		agency_center: [
				(agencyBounds.ne[0] - agencyBounds.sw[0]) / 2 + agencyBounds.sw[0]
				(agencyBounds.ne[1] - agencyBounds.sw[1]) / 2 + agencyBounds.sw[1]
		] }
	}
	Q.when(Agency.update(query, updateData).exec())



########################################################################################
### Exports
########################################################################################

module.exports =
	updateLastUpdateDate: updateLastUpdateDate
	updateAgencyCenter: updateAgencyCenter