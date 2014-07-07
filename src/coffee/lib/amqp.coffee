####################################################################
# Modules
####################################################################

os = require 'os'
util = require 'util'

amqp = require 'amqp'
Chance = require 'chance'
Promise = require 'bluebird'

logger = require '../log/logger'
config = require '../conf/config'


###########################################################
# Redis initialization
###########################################################

createClient = (name) ->

	amqpClientDeferred = Promise.pending()

	amqpClient = amqp.createConnection(
		{ host: config.amqp.hostname, port: config.amqp.port, clientProperties: { applicationName: config.appname, capabilities: { consumer_cancel_notify: true } } },
		{ defaultExchangeName: '', reconnect: true, reconnectBackoffStrategy: 'linear', reconnectExponentialLimit: 120000, reconnectBackoffTime: 1000 }
	)

	amqpClient.on 'ready', () ->
		amqpClientDeferred.fulfill()

	amqpClient.on 'error', (err) ->
		logger.info("[AMQP] Error message: #{err.message}")
		logger.info("[AMQP] Error message: #{err.stack}")

	amqpClientReady = amqpClientDeferred.promise


	amqpClient.publishJSON = (channel, message, callback) ->
		#logger.debug "[#{name}][AMQP][SEND][Channel:#{channel}] #{JSON.stringify(message, undefined, 2)}"
		#logger.debug "[#{name}][AMQP][SEND][Channel:#{channel}]"

		publish = () ->
			amqpClient.queue channel, { }, (queue) ->
				exchangeOpts = { type: 'fanout', confirm: true }
				amqpClient.exchange channel, exchangeOpts, (exchange) ->
					queue.bind exchange, channel, (data) ->
						exchange.publish channel, message, { }, (err, data) ->
							if exchangeOpts.confirm && callback
								callback(err, data)
						if !exchangeOpts.confirm && callback
							callback()

		if amqpClient.readyEmitted
			publish()
		else
			amqpClientReady.then publish

	amqpClient.publishText = (channel, message, callback) ->
		logger.debug "[#{name}][AMQP][SEND][Channel:#{channel}]"

		publish = () ->
			amqpClient.queue channel, { }, (queue) ->
				exchangeOpts = { type: 'fanout', confirm: true }
				amqpClient.exchange channel, exchangeOpts, (exchange) ->
					queue.bind exchange, channel, (data) ->
						exchange.publish channel, message, { }, (err, data) ->
							if exchangeOpts.confirm
								callback(err, data)
						if !exchangeOpts.confirm
							callback()

		if amqpClient.readyEmitted
			publish()
		else
			amqpClientReady.then publish


	amqpClient.subscribeTopic = (channel, channelHandler) ->
		uuid = new Chance().hash({ length: 4, casing: 'upper' })
		queueName = "#{channel}_#{uuid}".toUpperCase().replace(/[-]/g, "_")
		logger.debug "[#{name}][AMQP][SUBSCRIBE] Subcribing to channel '#{channel}' with queue: '#{queueName}'"

		subscribeTopic = () ->
			amqpClient.exchange channel, { type: "fanout" }, (exchange) ->
				queue = amqpClient.queue queueName, { ### Options ### }, (queue) ->
					queue.bind exchange, channel
					queue.subscribe (message) ->
						channelHandler.handleMessage channel, message

		if amqpClient.readyEmitted
			subscribeTopic()
		else
			amqpClientReady.then subscribeTopic


	amqpClient.subscribeQueue = (channel, options, channelHandler) ->
		queueName = "#{channel}"
		logger.debug "[#{name}][AMQP][SUBSCRIBE] Subcribing to channel '#{channel}' with queue: '#{queueName}'"

		subscribeQueue = () ->
			amqpClient.exchange channel, { type: "fanout" }, (exchange) ->
				queue = amqpClient.queue queueName, options, (queue) ->
					queue.bind exchange, channel
					queue.subscribe (message, headers, deliveryInfo, messageObject) ->
						channelHandler.handleMessage channel, message, headers, deliveryInfo, messageObject

		if amqpClient.readyEmitted
			subscribeQueue()
		else
			amqpClientReady.then subscribeQueue

	amqpClient

####################################################################
# Exports
####################################################################

module.exports =
	createClient: createClient
