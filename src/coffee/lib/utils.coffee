########################################################################################
### Modules
########################################################################################

logger = require 'winston'
request = require 'request'
moment = require 'moment'
_ = require('underscore')._
HtmlEntities = require 'html-entities'

cache = require './cache'

html5Entities = new HtmlEntities.Html5Entities()


########################################################################################
### Functions
########################################################################################

removeParameters = (url, parameters) ->
	for parameter in parameters
		urlparts = url.split('?')

		if urlparts.length >= 2

			urlBase = urlparts.shift()
			# Get first part, and remove from array
			queryString = urlparts.join("?")
			# Join it back up

			prefix = encodeURIComponent(parameter) + '='
			pars = queryString.split(/[&;]/g)

			i = pars.length

			i--
			# Reverse iteration as may be destructive
			while i > 0
				if pars[i].lastIndexOf(prefix, 0) != -1 # Idiom for string.startsWith
					pars.splice(i, 1)
				i--

			result = pars.join('&')
			url = urlBase + if result then '?' + result else ''

	url

getParameterByName = (url, name) ->
	#name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	name = name.replace(/[\[]/, "\\\\[").replace(/[\]]/, "\\\\]")
	regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
	results = regex.exec(url)
	if results == null
		""
	else
		decodeURIComponent(results[1].replace(/\+/g, " "))


sendJsonResponse = (options, data) ->
	callback = getParameterByName(options.req.url, 'callback')
	response = data

	if callback
		options.res.setHeader 'Content-Type', 'application/javascript'
		response = "#{callback}(#{JSON.stringify(response)});"
	else
		options.res.setHeader 'Content-Type', 'application/json'


#	logger.info "[" + options.url + "] Response sent: #{response}"
	options.res.send(response)


getContentType = (response) ->
	if response then response.headers["content-type"] else undefined


isContentTypeJsonOrScript = (contentType) ->
	contentType.indexOf('json') >= 0 || contentType.indexOf('script') >= 0


getCacheKey = (req) ->
	removeParameters(req.url, ['callback', '_'])


getUrlToFetch = (req) ->
	removeParameters(req.url, ['callback'])


getIfUseCache = (req) ->
	getParameterByName(req.url, 'cache') == 'false'


useCache = (options) ->
	!options.forceNoCache


isNumber = (n) ->
	!isNaN(parseFloat(n)) && isFinite(n)

responseData = (statusCode, statusMessage, data, options) ->
	if statusCode >= 200 && statusCode <= 299
		if options.contentType
			options.res.setHeader 'Content-Type', options.contentType

		sendJsonResponse(options, data)
	else
		logger.info "Status code: #{statusCode}, message: #{statusMessage}"
		options.res.send(statusMessage, statusCode)


getData = (options) ->
	try
		if !useCache(options)
			fetchDataFromUrl(options)
		else
			logger.info "[#{options.cacheKey}] Cache Key is: #{options.cacheKey}"
			logger.info "Checking if data for cache key [#{options.cacheKey}] is in cache"
			cache.get options.cacheKey, (err, data) ->
				if !err && data
					logger.info "[#{options.url}] A reply is in cache key: '#{options.cacheKey}', returning immediatly the reply"
					options.callback(200, "", data, options)
				else
					logger.info "[#{options.url}] No cached reply found for key: '#{options.cacheKey}'"
					fetchDataFromUrl(options)
	catch err
		errorMessage = err.name + ": " + err.message
		options.callback(500, errorMessage, undefined, options)


processResponse = (options, error, data, response) ->
	if error
		options.callback(500, "Server Error: #{error}", undefined, options)
	else if  data && data.error
			options.callback(500, "Server Error: #{data.error}", undefined, options)
	else if !data
		options.callback(404, "Not Found", undefined, options)
	else
		contentType = getContentType(response)
		logger.info "[#{options.url}] Http Response - Content-Type: #{contentType}"
		logger.info "[#{options.url}] Http Response - Headers: #{response.headers}"

		if !isContentTypeJsonOrScript(contentType)
			errorMessage = "[#{options.url}] Content-Type is not json or javascript: Not caching data and returning response directly"
			logger.info
			options.contentType = contentType
			options.callback(500, "Server Error: #{errorMessage}", undefined, options)
		else
			if options.transform
				options.transform data, (err, data) ->
					putInCacheAndSendResponse(err, data, options)
			else
				putInCacheAndSendResponse(undefined, data, options)

putInCacheAndSendResponse = (err, data, options) ->
	if (err)
		options.callback(500, "Server Error: #{err}", undefined, options)
	else if (!data)
		options.callback(400, "Not Found", undefined, options)
	else
		jsonData = JSON.stringify(data)
		logger.info "[#{options.url}] Fetched Response from url: #{jsonData.substr(0, 256)}"
		options.callback(200, "OK", jsonData, options)
		if useCache(options)
			cache.set(options.cacheKey, data, if options.cacheTimeout then options.cacheTimeout else 60 * 60)


fetchDataFromUrl = (options) ->
	logger.info "[#{options.url}] Fetching data from url"

	if (options.oauth)
		options.oauth.get options.url, options.credentials.accessToken, options.credentials.accessTokenSecret, (error, data, response) ->
			data = if data then JSON.parse(data) else data
			processResponse(options, error, data, response)
	else if (options.oauth2)
		options.oauth2.get options.url, options.credentials.accessToken, (error, data, response) ->
			data = if data then JSON.parse(data) else data
			processResponse(options, error, data, response)
	else
		headers = { "User-Agent": "Xebia-Mobile-Backend" }
		if options.accessToken
			headers["Authorization"] = "Bearer " + options.accessToken
		request.get {url: options.url, json: true, headers: headers}, (error, response, data) ->
			processResponse(options, error, data, response)


buildOptions = (req, res, url, cacheTimeout = 5 * 60, transform, accessToken) ->
	options =
		req: req,
		res: res,
		url: url,
		cacheKey: getCacheKey(req),
		forceNoCache: getIfUseCache(req),
		cacheTimeout: cacheTimeout,
		callback: responseData,
		transform: transform,
		accessToken: accessToken

	options

processRequest = (options) ->
	try
		getData(options)
	catch err
		errorMessage = err.name + ": " + err.message
		responseData(500, "Server Error: #{errorMessage}", undefined, options)

###
Return a random int, used by `utils.uid()`

@param {Number} min
@param {Number} max
@return {Number}
@api private
###
getRandomInt = (min, max) ->
	Math.floor(Math.random() * (max - min + 1)) + min


###
Return a unique identifier with the given `len`.

utils.uid(10);
// => "FDaS435D2z"

@param {Number} len
@return {String}
@api private
###
uid = (len) ->
	buf = []
	chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	charlen = chars.length
	i = 0

	while i < len
		buf.push chars[getRandomInt(0, charlen - 1)]
		++i
	buf.join ""

callbackDelayed = (callback, err, data, delay) ->
	setTimeout(
		() -> callback(err, data)
		delay
	)

stopWatchCallbak = (_callback) ->
	start = moment()

	(err, data) ->
		end = moment()
		duration = moment.duration(end.diff(start)).asMilliseconds()
		logger.info "Task ended in #{duration} ms"

		_callback err, data

isSame = (obj1, obj2, fields) ->
	for field, i in fields
		if obj1[field] != obj2[field]
			return false
	true

isNotSame = (obj1, obj2, fields) ->
	!isSame(obj1, obj2, fields)

htmlToPlainText = (html) ->
	content = html.replace(/<\/?([a-z][a-z0-9]*)\b[^>]*>?/gi, '')
	content = content.replace(/<!--(.*?)-->/g, '')
	content = content.replace(/\n\s*\n/g, '\n')
	content = html5Entities.decode(content)
	content = content.trim()


isInt = (n) ->
	typeof n is "number" and n % 1 is 0

getDayName = (date) ->
	days = [
		"Sunday"
		"Monday"
		"Tuesday"
		"Wednesday"
		"Thursday"
		"Friday"
		"Saturday"
	]
	days[date.getDay()]

formatDay = (date) ->
	day = (if (date.getDate() < 10) then "" + "0" + date.getDate() else date.getDate())
	month = (if ((date.getMonth() + 1) < 10) then "" + "0" + (date.getMonth() + 1) else (date.getMonth() + 1))
	year = date.getFullYear()
	"" + year + month + day

timeToSeconds = (time) ->
	if time instanceof Date
		timeParts = [
			time.getHours()
			time.getMinutes()
			time.getSeconds()
		]
	else
		timeParts = time.split(":")
		return null  unless timeParts.length is 3
	parseInt(timeParts[0], 10) * 60 * 60 + parseInt(timeParts[1], 10) * 60 + parseInt(timeParts[2], 10)

secondsToTime = (seconds) ->

	#check if seconds are already in HH:MM:SS format
	return seconds  if seconds.match(/\d+:\d+:\d+/)[0]
	hour = Math.floor(seconds / (60 * 60))
	minute = Math.floor((seconds - hour * (60 * 60)) / 60)
	second = seconds - hour * (60 * 60) - minute * 60
	((if (hour < 10) then "" + "0" + hour else hour)) + ":" + ((if (minute < 10) then "" + "0" + minute else minute)) + ":" + ((if (second < 10) then "" + "0" + second else second))


########################################################################################
### Exports
########################################################################################

module.exports =
	getData: getData
	responseData: responseData
	getIfUseCache: getIfUseCache
	fetchDataFromUrl: fetchDataFromUrl
	getCacheKey: getCacheKey
	getUrlToFetch: getUrlToFetch
	buildOptions: buildOptions
	processRequest: processRequest
	getParameterByName: getParameterByName
	uid: uid
	callbackDelayed: callbackDelayed
	stopWatchCallbak: stopWatchCallbak
	isSame: isSame
	isNotSame: isNotSame
	htmlToPlainText: htmlToPlainText
	isNumber: isNumber

	isInt: isInt
	getDayName: getDayName
	formatDay: formatDay
	timeToSeconds: timeToSeconds
	secondsToTime: secondsToTime