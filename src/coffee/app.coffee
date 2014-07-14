########################################################################################
### Global - Startup
########################################################################################
start = new Date()

heapdump = require 'heapdump'

config = require './conf/config'
logger = require './log/logger'
amqp = require './lib/amqp'
JobStartConsumer = require './service/JobStartConsumer'

if config.devMode
	logger.info "Dev Mode enabled."

if config.monitoring.newrelic.apiKey
	logger.info "Initializing NewRelic with apiKey: '#{config.monitoring.newrelic.apiKey}'"
	newrelic = require 'newrelic'


logger.info "Application Name: #{config.appname}"
logger.info "Env: #{JSON.stringify config, undefined, 2}"



########################################################################################
### Express
########################################################################################

express = require 'express'

requestLogger = require './lib/requestLogger'
allowCrossDomain = require './lib/allowCrossDomain'

app = express()

gracefullyClosing = false

app.configure ->
	logger.info "Environment: #{app.get('env')}"
	app.set 'port', config.port or process.env.PORT or 8000
	app.set 'jsonp callback name', 'callback'
	app.disable "x-powered-by"

	#	app.use connectDomain()
	app.use (req, res, next) ->
		return next() unless gracefullyClosing
		res.setHeader "Connection", "close"
		res.send 502, "Server is in the process of restarting"

	app.use (req, res, next) ->
		req.forwardedSecure = (req.headers["x-forwarded-proto"] == "https")
		next()

	app.use express.json()
	app.use express.urlencoded()
	app.use express.cookieParser()

	app.use express.logger()
	app.use allowCrossDomain()

	app.use requestLogger()

	app.use app.router

	app.use (err, req, res, next) ->
		console.error "Error: #{err}, Stacktrace: #{err.stack}"
		res.send 500, "Something broke! Error: #{err}, Stacktrace: #{err.stack}"


app.configure 'development', () ->
	app.use express.errorHandler
		dumpExceptions: true,
		showStack: true


app.configure 'production', () ->
	app.use express.errorHandler()



########################################################################################
### Routes
########################################################################################

gtfsImportController = require './controller/importController'

app.get "/import", gtfsImportController.importData




########################################################################################
### Job stuff
########################################################################################

logger.info "[#{process.pid}] Initializing Job Start consumer"
amqpClient = amqp.createClient "APP"

amqpClient.subscribeTopic "JOB_START", new JobStartConsumer(amqpClient)



########################################################################################
### Http Server - Startup
########################################################################################

http = require "http"
http.globalAgent.maxSockets = 100

httpServer = app.listen app.get('port')

process.on 'SIGTERM', ->
	logger.info "Received kill signal (SIGTERM), shutting down gracefully."
	gracefullyClosing = true
	httpServer.close ->
		logger.info "Closed out remaining connections."
		process.exit()

	setTimeout ->
		console.error "Could not close connections in time, forcefully shutting down"
		process.exit(1)
	, 30 * 1000

process.on 'uncaughtException', (err) ->
	console.error "An uncaughtException was found, the program will end. #{err}, stacktrace: #{err.stack}"
	process.exit 1

logger.info "Express listening on port: #{app.get('port')}"
logger.info "Started in #{(new Date().getTime() - start.getTime()) / 1000} seconds"
