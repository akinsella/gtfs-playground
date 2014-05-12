########################################################################################
### Modules
########################################################################################

mongoose = require 'mongoose'

logger = require '../log/logger'
config = require '../conf/config'


########################################################################################
### Functions
########################################################################################

logger.info("config: " + JSON.stringify(config))
logger.info("config: " + JSON.stringify(config.mongo))

url = "mongodb://#{config.mongo.hostname}:#{config.mongo.port}/#{config.mongo.dbname}"
options =
	db: { native_parser: false }
	server: { poolSize: 20 }
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
