########################################################################################
### Modules
########################################################################################

mongoose = require 'mongoose'

logger = require '../log/logger'
config = require '../conf/config'


########################################################################################
### Functions
########################################################################################

logger.info "config: #{JSON.stringify(config.mongo)}"

url = "mongodb://#{config.mongo.url}/#{config.mongo.dbname}"
options =
	db: { native_parser: config.mongo.nativeParser }
	mongos: config.mongo.mongosEnabled
	server: { poolSize: config.mongo.poolSize }
	user: config.mongo.username
	pass: config.mongo.password


logger.info("Mongo Url: #{url}")
mongoose.connect url, options


client = mongoose.connection
client.on 'error', console.error.bind(console, 'connection error:')
client.once 'open', () ->
	logger.info "Connected to MongoBD on url: #{url}"


########################################################################################
### exports
########################################################################################

module.exports =
	client: client
	Schema: mongoose.Schema
