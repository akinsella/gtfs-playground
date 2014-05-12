########################################################################################
### Modules
########################################################################################

mongo = require '../lib/mongo'
utils = require '../lib/utils'


########################################################################################
### Functions
########################################################################################

StopTimeSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	trip_id: { type: String, index: true }
	arrival_time: { type: String, get: utils.secondsToTime, set: utils.timeToSeconds }
	departure_time: { type: String, index: true, get: utils.secondsToTime, set: utils.timeToSeconds }
	stop_id: { type: String, index: true }
	stop_sequence: { type: Number, index: true }
	stop_headsign: { type: String }
	pickup_type: { type: String }
	drop_off_type: { type: String }
	shape_dist_traveled: { type: String }
)

StopTime = mongo.client.model('StopTime', StopTimeSchema);


########################################################################################
### Exports
########################################################################################

module.exports = StopTime
