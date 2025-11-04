class_name Gateway extends RefCounted

static func get_url() -> String:
	var settings: NetworkSettings = NetworkSettings.Load()
	if settings != null and settings.gateway_url != "":
		return settings.gateway_url
	return ProjectSettings.get_setting("gdmmorpg/network/gateway_url", "http://localhost:8080")

static func get_server_token() -> String:
	var settings: NetworkSettings = NetworkSettings.Load()
	if settings != null:
		return settings.gateway_server_token
	return ProjectSettings.get_setting("gdmmorpg/network/gateway_server_token", "default_server_token")

static func get_realmlist() -> Array:
	var jwt_token: String = ""
	if ContextInit.current_context == ContextInit.Context.CLIENT:
		jwt_token = ClientInit.get_instance()._jwt_token
	else:
		jwt_token = get_server_token()

	var url: String = ("%s/client/realmlist" % get_url()).strip_edges()
	
	# Create an HTTP requester
	var requester := AwaitableHTTPRequest.new()
	ContextInit.add_child(requester)

	# Make the request with JWT authentication
	var resp := await requester.async_request(url, [
		"Authorization: Bearer %s" % jwt_token
	], HTTPClient.METHOD_GET, "")

	# Check for request errors
	if not resp.success():
		Log.error("HTTP request to gateway failed: ", error_string(resp._error))
		return []

	if  not resp.status_ok():
		Log.error("Gateway returned error status: %d" % resp.status)
		return []
	
	var realmlist: Array = resp.body_as_json()
	return realmlist

static func get_characterslist() -> Array:
	var jwt_token: String = ""
	if ContextInit.current_context == ContextInit.Context.CLIENT:
		jwt_token = ClientInit.get_instance()._jwt_token
	else:
		Log.error("Characters list can only be fetched in client context.")
		return []

	var url: String = ("%s/client/characterslist" % get_url()).strip_edges()
	
	# Create an HTTP requester
	var requester := AwaitableHTTPRequest.new()
	ContextInit.add_child(requester)

	# Make the request with JWT authentication
	var resp := await requester.async_request(url, [
		"Authorization: Bearer %s" % jwt_token
	], HTTPClient.METHOD_GET, "")

	# Check for request errors
	if not resp.success():
		Log.error("HTTP request to gateway failed: ", error_string(resp._error))
		return []

	if  not resp.status_ok():
		Log.error("Gateway returned error status: %d" % resp.status)
		return []
	
	var characterslist: Array = resp.body_as_json()
	return characterslist