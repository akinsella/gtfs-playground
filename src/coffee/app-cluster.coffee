fs = require 'fs'

recluster = require 'recluster'

logger = require './log/logger'

cluster = recluster "#{__dirname}/app"

cluster.on "fork", (worker) ->
	logger.info "[#{worker.process.pid}] Forking cluster"

cluster.on "setup", (worker) ->
	logger.info "[#{worker.process.pid}] Setuping cluster"

cluster.on "listening", (worker, address) ->
	logger.info "[#{worker.process.pid}] Worker listening"

cluster.on "online", (worker) ->
	logger.info "[#{worker.process.pid}] Worker online"

cluster.on "disconnect", (worker) ->
	logger.info "[#{worker.process.pid}] Worker disconnecting Cluster"

cluster.on "exit", (worker) ->
	logger.info "[#{worker.process.pid}] Worker exiting Cluster"

cluster.run()

fs.watchFile "package.json", (curr, prev) ->
	logger.info "Package.json changed, reloading cluster..."
	cluster.reload()

process.on "SIGUSR2", ->
	logger.info "Got SIGUSR2, reloading cluster..."
	cluster.reload()

logger.info "Spawned cluster, kill -s SIGUSR2 #{process.pid} to reload"
