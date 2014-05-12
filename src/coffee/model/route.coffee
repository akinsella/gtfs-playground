########################################################################################
### Modules
########################################################################################

mongo = require '../lib/mongo'


########################################################################################
### Functions
########################################################################################

RouteSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	route_id: { type: String }
	agency_id: { type: String }
	route_short_name: { type: String }
	route_long_name: { type: String }
	route_desc: { type: String }
	route_type: { type: String }
	route_url: { type: String }
	route_color: { type: String }
	route_text_color: { type: String }
)

Route = mongo.client.model('Route', RouteSchema)


########################################################################################
### Exports
########################################################################################

module.exports = Route
