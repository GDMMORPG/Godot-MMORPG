extends Button

signal on_authenticated(jwt: String)
signal on_failure(reason: String)


func _ready():
	pressed.connect(_on_button_pressed)
	
### Handle button press to start login process.
func _on_button_pressed():
	_login_with_gateway()

### Login through the gateway using oauth.
func _login_with_gateway():
	if not ClientInit._instance._jwt_token.is_empty():
		on_authenticated.emit(ClientInit._instance._jwt_token)
		return
	
	var auth_result: Dictionary = await AuthAPI.oauth(Gateway.get_url() + "/login")
	if auth_result.has('error'):
		var error_msg: String = auth_result['error']
		Log.error("Login failed: ", error_msg)
		on_failure.emit(error_msg)
		return

	if not auth_result.has('params'):
		Log.error("Login failed: No parameters returned.")
		on_failure.emit("No parameters returned")
		return
	var params: Dictionary = auth_result['params']
	if params.has('jwt'):
		var jwt: String = params['jwt']
		on_authenticated.emit(jwt)
	else:
		Log.error("Login failed: JWT not found in parameters.")
		on_failure.emit("JWT not found")
