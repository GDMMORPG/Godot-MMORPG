extends Node
class_name OAuthinator

signal oauth_completed(params: Dictionary)

const PORT: int = 54320

const HTTPParser = preload("res://addons/oauth/utils/httpparser.gd")

var http_server: TCPServer

func _ready() -> void:
	http_server = TCPServer.new()
	var err = http_server.listen(PORT)
	if err != OK:
		push_error("Failed to start HTTP server on port %d" % PORT)
		return
	set_process(true)

func _process(delta: float) -> void:
	if http_server.is_connection_available():
		var connection = http_server.take_connection()
		connection.set_no_delay(true)
		var request = connection.get_string(connection.get_available_bytes())
		if request:
			# print("Received request:\n%s" % request)
			var parsed_request = HTTPParser.parse_http_request(request)
			oauth_completed.emit(parsed_request)
			var body: String = "<!DOCTYPE html>
<html>
<head>
	<title>OAuth Complete</title>
</head>
<body>
	<h1>OAuth flow completed. You can close this window.</h1>
</body>
</html>"
			var response: String = "HTTP/1.1 200 OK\r\n"
			response += "Content-Type: text/html; charset=UTF-8\r\n"
			response += "Content-Length: %d\r\n" % body.length()
			response += "Connection: close\r\n"
			response += "\r\n"
			response += body
			if connection.put_data(response.to_utf8_buffer()) != OK:
				push_error("Failed to send response")
		queue_free()

func _exit_tree() -> void:
	if http_server.is_listening():
		http_server.stop()
