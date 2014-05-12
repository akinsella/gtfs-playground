########################################################################################
### Modules
########################################################################################

mongo = require '../lib/mongo'


########################################################################################
### Functions
########################################################################################

CalendarSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	service_id: { type: String }
	monday: { type: String }
	tuesday: { type: String }
	wednesday: { type: String }
	thursday: { type: String }
	friday: { type: String }
	saturday: { type: String }
	sunday: { type: String }
	start_date: { type: String }
	end_date: { type: String }
)

Calendar = mongo.client.model('Calendar', CalendarSchema)


########################################################################################
### Exports
########################################################################################

module.exports = Calendar
