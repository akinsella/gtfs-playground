os = require 'os'
util = require 'util'
amqp = require 'amqp'
uuid = require 'uuid'
Chance = require 'chance'
Promise = require 'bluebird'
logger = require '../log/logger'
config = require '../conf/config'

createClient = (amqpClientName) ->
	publishExchangeCache = {}

	amqpClientDeferred = Promise.pending()

	amqpClient = amqp.createConnection(
		{ host: config.amqp.hostname, port: config.amqp.port, login: config.amqp.login, password: config.amqp.password, authMechanism: "AMQPLAIN", vhost: config.amqp.vhost, clientProperties: { applicationName: config.appname, capabilities: { consumer_cancel_notify: true } } },
		{ defaultExchangeName: "", reconnect: true, reconnectBackoffStrategy: "linear", reconnectExponentialLimit: 120000, reconnectBackoffTime: 1000 }
	)

	amqpClient.uuid = uuid.v4()
	amqpClient.on "ready", () ->
		publishExchangeCache = {}
		logger.info "[#{amqpClientName}][AMQP][#{amqpClient.uuid}] Ready"
		amqpClientDeferred.fulfill(amqpClient)

	amqpClient.on "connect", () ->
		logger.info "[#{amqpClientName}][AMQP][#{amqpClient.uuid}] Connected"

	amqpClient.on "close", () ->
		logger.info "[#{amqpClientName}][AMQP][#{amqpClient.uuid}] Connection closed"

	amqpClient.on "error", (err) ->
		logger.error "[#{amqpClientName}][AMQP][#{amqpClient.uuid}] Error message: #{err.message} - Stacktrace: #{err.stack} - Error: #{JSON.stringify(err)}"
		amqpClientDeferred.reject(err)

	amqpClientReady = amqpClientDeferred.promise


	amqpClient.publishMessage = (channel, message, callback) ->
		exchangeOpts = { type: "fanout", confirm: true }

		jsonMessage = JSON.stringify(message)
		if logger.isTraceEnabled()
			logger.trace "[#{amqpClientName}][AMQP][#{amqpClient.uuid}][PUBLISH][Channel:#{channel}] #{jsonMessage}"
		else
			logger.debug "[#{amqpClientName}][AMQP][#{amqpClient.uuid}][PUBLISH][Channel:#{channel}] #{jsonMessage.substring(0, Math.min(30, jsonMessage.length))}"  if logger.isDebugEnabled()
		publishMessage = (exchange) ->
			exchange.publish channel, jsonMessage, {}, (err, data) ->
				logger.error "[#{amqpClientName}][AMQP][#{amqpClient.uuid}][PUBLISH][Channel:#{channel}] Got an error on send - Error: #{JSON.stringify(error)}"  if err
				callback err, data  if exchangeOpts.confirm and callback
				callback()  unless exchangeOpts.confirm

		publish = () ->
			exchange = publishExchangeCache[channel]
			if exchange
				publishMessage exchange
			else
				amqpClient.queue channel, {}, (queue) ->
					amqpClient.exchange channel, exchangeOpts, (exchange) ->
						queue.bind exchange, channel, (data) ->
							publishExchangeCache[channel] = exchange
							publishMessage exchange

		if amqpClient.readyEmitted
			publish()
		else
			amqpClientReady.then publish


	amqpClient.subscribeTopic = (channel, channelHandler) ->
		channelUuid = new Chance().hash({ length: 4, casing: 'upper' })
		queueName = "#{channel}_#{channelUuid}".toUpperCase().replace(/[-]/g, "_")
		logger.info "[#{amqpClientName}][AMQP][#{amqpClient.uuid}][SUBSCRIBE] Subscribing to channel '#{channel}' with topic: '#{queueName}'"
		subscribeTopic = () ->
			amqpClient.exchange channel, { type: "fanout" }, ((exchange) -> ), (exchange) ->
				amqpClient.queue queueName, {}, (queue) ->
					queue.bind exchange, channel
					queue.subscribe (message) ->
						channelHandler.handleMessage channel, message

		if amqpClient.readyEmitted
			subscribeTopic()
		else
			amqpClientReady.then subscribeTopic

	amqpClient.subscribeQueue = (channel, options, channelHandler) ->
		queueName = "#{channel}"
		logger.info "[#{amqpClientName}][AMQP][#{amqpClient.uuid}][SUBSCRIBE] Subscribing to channel '#{channel}' with queue: '#{queueName}'"
		subscribeQueue = () ->
			amqpClient.exchange channel, { type: "fanout" }, (exchange) ->
				amqpClient.queue queueName, options, (queue) ->
					queue.bind exchange, channel
					queue.subscribe (message, headers, deliveryInfo, messageObject) ->
						channelHandler.handleMessage channel, message, headers, deliveryInfo, messageObject

		if amqpClient.readyEmitted
			subscribeQueue()
		else
			amqpClientReady.then subscribeQueue

	amqpClient

module.exports =
	createClient: createClient