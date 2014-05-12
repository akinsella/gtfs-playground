########################################################################################
### Modules
########################################################################################

mongo = require '../lib/mongo'


########################################################################################
### Functions
########################################################################################

FeedInfoSchema = new mongo.Schema(
	agency_key: { type: String, index: true }
	feed_publisher_name: { type: String }
	feed_publisher_url: { type: String }
	feed_lang: { type: String }
	feed_start_date: { type: String }
	feed_end_date: { type: String }
	feed_version: { type: String }
)

FeedInfo = mongo.client.model('FeedInfo', FeedInfoSchema)


########################################################################################
### Exports
########################################################################################

module.exports = FeedInfo