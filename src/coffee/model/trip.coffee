########################################################################################
### Modules
########################################################################################

mongo = require '../lib/mongo'


########################################################################################
### Functions
########################################################################################

TripSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	route_id: { type: String, index: true }
	service_id: { type: String, index: true }
	trip_id: { type: String }
	trip_headsign: { type: String }
	trip_short_name: { type: String }
	direction_id: { type: Number, index: true, min: 0, max: 1 }
	block_id: { type: String }
	shape_id: { type: String }
)

Trip = mongo.client.model('Trip', TripSchema)


########################################################################################
### Exports
########################################################################################

module.exports = Trip
