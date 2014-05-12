########################################################################################
### Modules
########################################################################################

mongo = require('../lib/mongo')


########################################################################################
### Functions
########################################################################################

FareRuleSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	fare_id: { type: String }
	route_id: { type: String }
	origin_id: { type: String }
	destination_id: { type: String }
	contains_id: { type: String }
)

FareRule = mongo.client.model('FareRule',FareRuleSchema)


########################################################################################
### Exports
########################################################################################

module.exports = FareRule
