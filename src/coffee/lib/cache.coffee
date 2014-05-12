########################################################################################
### Modules
########################################################################################

moment = require 'moment'

CacheEntry = require '../model/cacheEntry'


########################################################################################
### Functions
########################################################################################

get = (key, callback) ->
	CacheEntry.findOne { key: key }, (err, cacheEntry) ->
		if (err || !cacheEntry)
			if (callback)
				callback(err, undefined)
		else
			now = moment()
			lastModified = moment(cacheEntry.lastModified)
			if (cacheEntry.ttl == -1)
				if (callback)
					callback(err, JSON.parse(cacheEntry.data))
			else
				lastModifiedWithTtl = lastModified.add('seconds', cacheEntry.ttl)
				if (now.isAfter(lastModifiedWithTtl))
					cacheEntry.remove()
					if (callback)
						callback(err, undefined)
				else
					if (callback)
						callback(err, JSON.parse(cacheEntry.data))


set = (key, data, ttl, callback) ->
	cacheEntry = new CacheEntry({ key:key, data:JSON.stringify(data), ttl:ttl })
	CacheEntry.remove({key:key}, (err) ->
		if (err)
			if (callback)
				callback(err)
		else
			cacheEntry.save (err) ->
				if (callback)
					callback(err)
	)

remove = (key, callback) ->
	CacheEntry.findOneAndRemove { key: key }, (err, cacheEntry) ->
		if (callback)
			callback(err, cacheEntry)

clear = (callback) ->
	CacheEntry.findAndRemove { }, (err) ->
		if (callback)
			callback(err)


########################################################################################
### Exports
########################################################################################

module.exports =
	get : get
	set : set
	remove : remove
	clear : clear
