fs = require 'fs'
csv = require 'csv-streamify'
logger = require './log/logger'
BatchStream = require 'batch-stream'
devnull = require 'dev-null'

AmqpTaskSubmitterStream = require './stream/AmqpTaskSubmitterStream'

StopTime = require './model/stopTime'
JSONStream = require 'JSONStream'
fsStream = fs.createReadStream("/Users/akinsella/Workspace/Projects/gtfs-playground/downloads/stop_times.txt")
csvStream = csv({ objectMode: true, newline:'\r\n' })
batchStream = new BatchStream({ size : 1000 })

GTFSFile = { fileNameBase: "stop_times", collection: StopTime }
agency = { key: 'RATP', url: 'http://localhost/data/gtfs_paris_20140502.zip' }

lineIndex = 0

amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessRecord")


fsStream
.pipe(csvStream)
.on 'data', (data) ->
	lineIndex++
	logger.info "[#{GTFSFile.fileNameBase}][#{lineIndex}] Processed data" if lineIndex % 100000 == 0
.pipe(batchStream)
.pipe(JSONStream.stringify(false))
.pipe(devnull())
