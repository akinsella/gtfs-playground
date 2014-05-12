########################################################################################
### Modules
########################################################################################

mongo = require '../lib/mongo'


########################################################################################
### Functions
########################################################################################

FrequenciesSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	trip_id: { type: String }
	start_time: { type: String }
	end_time: { type: String }
	headway_secs: { type: String }
	exact_times: { type: String }
)

Frequencies = mongo.client.model('Frequencies', FrequenciesSchema);


########################################################################################
### Exports
########################################################################################

module.exports = Frequencies