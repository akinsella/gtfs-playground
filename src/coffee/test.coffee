#agent = require 'webkit-devtools-agent'
heapdump = require 'heapdump'
fs = require 'fs'
csv = require 'csv-streamify'
BatchStream = require 'batch-stream'
devnull = require 'dev-null'
split = require 'split'
JSONStream = require 'JSONStream'

logger = require './log/logger'
StopTime = require './model/stopTime'
AmqpTaskSubmitterStream = require './stream/AmqpTaskSubmitterStream'


GTFSFile = { fileNameBase: "stop_times", collection: StopTime }
agency = { key: 'RATP', url: 'http://localhost/data/gtfs_paris_20140502.zip' }


fsStream = fs.createReadStream("/Users/akinsella/Workspace/Projects/gtfs-playground/downloads/stop_times.txt")


csvLineIndex = 0
csvStream = csv({ objectMode: true, newline:'\r\n' })
csvStream.on 'data', (data) ->
	csvLineIndex++
	logger.info "[#{GTFSFile.fileNameBase}][#{csvLineIndex}] Processed data" if csvLineIndex % 100000 == 0
csvStream.on 'drain', () ->
	logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{csvLineIndex}] drain"


splitRead = 0
splitStream = split()
splitStream.on 'data', () ->
	splitRead++
	logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{splitRead}] Batch processed: #{splitRead}" if splitRead % 100000 == 0
splitStream.on 'drain', () ->
	logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{splitRead}] drain"


batchRead = 0
batchStream = new BatchStream({ size : 10000, highWaterMark: 100 })
batchStream.on 'data', () ->
	batchRead++
	logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] Batch processed: #{batchRead}" if batchRead % 100 == 0
batchStream.on 'drain', () ->
	logger.info "[BATCH][#{GTFSFile.fileNameBase}][#{batchRead}] drain"


amqpRead = 0
amqpTaskSubmitterStream = new AmqpTaskSubmitterStream("ProcessCsvEntries", { highWaterMark: 50, agency: { key: "RATP" } })
amqpTaskSubmitterStream.on 'data', () ->
	amqpRead++
	logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] AMQP reads: #{amqpRead}" if amqpRead % 100000 == 0
amqpTaskSubmitterStream.on 'drain', () ->
	logger.info "[AMQP][#{GTFSFile.fileNameBase}][#{amqpRead}] drain"


fsStream
.pipe(splitStream)
.pipe(batchStream)
.pipe(amqpTaskSubmitterStream)
