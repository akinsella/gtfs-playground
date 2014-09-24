########################################################################################
### Modules
########################################################################################

logger = require 'winston'
request = require 'request'
moment = require 'moment'
_ = require('underscore')._
HtmlEntities = require 'html-entities'
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

isNumber = (n) ->
	!isNaN(parseFloat(n)) && isFinite(n)


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
	getParameterByName: getParameterByName
	callbackDelayed: callbackDelayed
	stopWatchCallbak: stopWatchCallbak
	htmlToPlainText: htmlToPlainText
	isNumber: isNumber
	isInt: isInt
	getDayName: getDayName
	formatDay: formatDay
	timeToSeconds: timeToSeconds
	secondsToTime: secondsToTime