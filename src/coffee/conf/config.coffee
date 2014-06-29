########################################################################################
### Modules
########################################################################################

_ = require('underscore')._



########################################################################################
### Config
########################################################################################

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
		monitoring:
			newrelic:
				apiKey: process.env.NEW_RELIC_API_KEY
				appName: process.env.NEW_RELIC_APP_NAME
		feature:
			stopWatch: true
		logging:
			basePath = "#{__dirname}"
		amqp:
			hostname: "127.0.0.1"
			port: "5672"
		bokeh:
			dealer: "tcp://127.0.0.1:8001"
			router: "tcp://127.0.0.1:8002"
			store:
				type: "memory"
				maxConnections: 100
			log:
				level: "debug"
				path:  "#{__dirname}/../log/bokeh.log"
		downloads:
			directory: 'downloads'


	config = _.extend({}, localConfig)



########################################################################################
### Exports
########################################################################################

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
	logging: config.logging
	bokeh: config.bokeh
	amqp: config.amqp
	downloads: config.downloads



