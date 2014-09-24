########################################################################################
### Modules
### #####################################################################################

_ = require('underscore')
moment = require('moment')


########################################################################################
### Config
### #####################################################################################

if !config
	localConfig =
		hostname: process.env.APP_HOSTNAME || "localhost"
		port: process.env.APP_HTTP_PORT || "8000"
		appname: 'GTFS Playground'
		devMode: process.env.DEV_MODE == "true"
		verbose: true
		processNumber: process.env.INDEX_OF_PROCESS || 0
		mongo:
			dbname: process.env.MONGO_DBNAME || "gtfs"
			hostname: process.env.MONGO_HOSTNAME || "localhost"
			port: process.env.MONGO_PORT || 27017
			username: process.env.MONGO_USERNAME # 'gtfs-playground'
			password: process.env.MONGO_PASSWORD # 'Password123'
			nativeParser: if process.env.MONGO_NATIVE_PARSER != undefined then (process.env.MONGO_NATIVE_PARSER == "true") else true
			poolSize: process.env.MONGO_POOL_SIZE || 5
		monitoring:
			newrelic:
				apiKey: process.env.NEW_RELIC_API_KEY
				appName: process.env.NEW_RELIC_APP_NAME
		feature:
			stopWatch: true
		logger:
			threshold: process.env.LOGGER_THRESHOLD_LEVEL || 'info'
			console:
				level: process.env.LOGGER_CONSOLE_THRESHOLD_LEVEL || 'info'
			file:
				level: process.env.LOGGER_FILE_THRESHOLD_LEVEL || 'info'
				directory: process.env.LOGGER_FILE_DIRECTORY || './logs'
				filename: process.env.LOGGER_FILE_FILENAME || "output-#{moment().format("YYYY-MM-DD")}.log"
		metrics:
			enabled: process.env.METRICS_ENABLED == 'true'
			sse:
				enabled: process.env.METRICS_SSE_ENABLED == 'true'
			graphite:
				enabled: process.env.METRICS_GRAPHITE_ENABLED == 'true',
				baseURL: process.env.METRICS_GRAHPITE_BASE_URL || "plaintext://localhost:2003/"
		amqp:
			hostname: (process.env.AMQP_HOSTNAME || 'localhost').split(','),
			port: process.env.AMQP_PORT || 5672,
			login: process.env.AMQP_LOGIN || 'guest',
			password: process.env.AMQP_PASSWORD || 'guest',
			vhost: process.env.AMQP_VHOST || '/'
		graphite:
			baseURL: process.env.GRAPHITE_BASE_URL || "plaintext://localhost:2003/"
		bokeh:
			dealer: "tcp://127.0.0.1:8001"
			router: "tcp://127.0.0.1:8002"
			store:
				type: "memory"
				maxConnections: 100
			log:
				level: "debug"
				path: "#{__dirname}/../log/bokeh.log"
		downloads:
			directory: 'downloads'


	config = _.extend({}, localConfig)


########################################################################################
### Exports
### #####################################################################################

module.exports =
	devMode: config.devMode
	verbose: config.verbose
	hostname: config.hostname
	processNumber: config.processNumber
	port: config.port
	appname: config.appname
	mongo: config.mongo
	monitoring: config.monitoring
	feature: config.feature
	logger: config.logger
	bokeh: config.bokeh
	amqp: config.amqp
	downloads: config.downloads
	metrics: config.metrics



