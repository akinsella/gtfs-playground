########################################################################################
### Functions
########################################################################################

# Simple route middleware to ensure user is authenticated.
#   Use this route middleware on any resource that needs to be protected.  If
#   the request is authenticated (typically via a persistent login session),
#   the request will proceed.  Otherwise, the user will be redirected to the
#   login page.
ensureAuthenticated = (req, res, next) =>
	if req.isAuthenticated()
		next()
	else
		res.send 401, "Unauthorized"
		return


########################################################################################
### Exports
########################################################################################

module.exports =
	ensureAuthenticated: ensureAuthenticated