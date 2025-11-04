extends Node

signal oauth_completed(params: Dictionary)

var oauthinator_instance: OAuthinator = null

var _data: Dictionary = {}

func cancel() -> void:
	if is_instance_valid(oauthinator_instance) and not oauthinator_instance.is_queued_for_deletion():
		oauthinator_instance.queue_free()

func oauth(login_url: String, expiration_duration_seconds: float = 120.0, use_external: bool = true) -> Dictionary:
	expiration_duration_seconds = max(expiration_duration_seconds, 1.0) # Minimum of 1 second
	var timer: Timer = Timer.new()
	timer.wait_time = expiration_duration_seconds
	timer.one_shot = true
	timer.autostart = true
	if oauthinator_instance == null:
		oauthinator_instance = OAuthinator.new()
		oauthinator_instance.oauth_completed.connect(func(params: Dictionary) -> void:
			_data = params
			oauth_completed.emit.call_deferred(params)
			timer.timeout.emit()
		)
		add_child(oauthinator_instance)

	if use_external:
		OS.shell_open(login_url)
	else:
		push_warning("In-app browser not implemented; defaulting to external browser.")

	oauthinator_instance.add_child(timer)

	await timer.timeout
	# Timeout handling
	if timer.time_left <= 0.0:
		_data = {
			"error": "OAuth process timed out."
		}
		oauth_completed.emit.call_deferred(_data)

	await oauth_completed
	
	# Clean up
	if is_instance_valid(oauthinator_instance) and not oauthinator_instance.is_queued_for_deletion():
		oauthinator_instance.queue_free()

	return _data
