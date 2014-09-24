########################################################################################
### Module
########################################################################################

fs = require("fs")
mkdirp = require("mkdirp")
moment = require("moment")
winston = require("winston")
_ = require("underscore")
config = require("../conf/config")


########################################################################################
### Functions
########################################################################################

loggerConfig =
	levels:
		trace: 0
		debug: 1
		info: 2
		warn: 3
		error: 4

	colors:
		trace: "magenta"
		debug: "blue"
		info: "green"
		warn: "yellow"
		error: "red"

	transports:
		console:
			level: config.logger.console.level
			colorize: true
			timestamp: "YYYY-MM-DD HH:mm:ss.SSS"

		file:
			dir: config.logger.file.directory
			filename: config.logger.file.filename
			level: config.logger.file.level
			json: false
			timestamp: "YYYY-MM-DD HH:mm:ss.SSS"
			maxsize: 1024 * 1024 * 10

winston.addColors loggerConfig.colors
mkdirp.sync "" + loggerConfig.transports.file.dir  unless fs.existsSync("" + loggerConfig.transports.file.dir)
console.log "Logging to file: '" + loggerConfig.transports.file.dir + "/" + loggerConfig.transports.file.filename + "'\n"
logger = new winston.Logger(
	level: config.logger.threshold
	levels: loggerConfig.levels
	transports: [new winston.transports.Console(
		level: loggerConfig.transports.console.level
		levels: loggerConfig.levels
		colorize: loggerConfig.transports.console.colorize
		timestamp: ->
			moment(Date.now()).format loggerConfig.transports.console.timestamp
	)]
)
logger.isLevelEnabled = (level) ->
	_.any @transports, (transport) ->
		(transport.level and logger.levels[transport.level] <= logger.levels[level]) or (not transport.level and logger.levels[logger.level] <= logger.levels[level])


isDebugEnabled = logger.isLevelEnabled("debug")
logger.isDebugEnabled = ->
	isDebugEnabled

isTraceEnabled = logger.isLevelEnabled("trace")
logger.isTraceEnabled = ->
	isTraceEnabled

isInfoEnabled = logger.isLevelEnabled("info")
logger.isInfoEnabled = ->
	isInfoEnabled


########################################################################################
### Exports
########################################################################################

module.exports = logger
