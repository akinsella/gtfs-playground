fs = require 'fs'

recluster = require 'recluster'

logger = require './log/logger'

cluster = recluster "#{__dirname}/app"

cluster.on "fork", (worker) ->
	logger.info "Forking cluster: #{worker.process.pid}"

cluster.on "setup", (worker) ->
	logger.info "Setuping cluster: #{worker.process.pid}"

cluster.on "listening", (worker, address) ->
	logger.info "Worker listening at address: #{address}: #{worker.process.pid}"

cluster.on "online", (worker) ->
	logger.info "Worker online: #{worker.process.pid}"

cluster.on "disconnect", (worker) ->
	logger.info "Worker disconnecting Cluster: #{worker.process.pid}"

cluster.on "exit", (worker) ->
	logger.info "Worker exiting Cluster: #{worker.process.pid}"

cluster.run()

fs.watchFile "package.json", (curr, prev) ->
	logger.info "Package.json changed, reloading cluster..."
	cluster.reload()

process.on "SIGUSR2", ->
	logger.info "Got SIGUSR2, reloading cluster..."
	cluster.reload()

logger.info "Spawned cluster, kill -s SIGUSR2 #{process.pid} to reload"
