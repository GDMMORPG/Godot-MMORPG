extends RefCounted

static func parse_http_request(request: String) -> Dictionary:
	var lines = request.split("\r\n")
	var request_line = lines[0].split(" ")
	var method = request_line[0]
	var path = request_line[1]
	var headers = {}
	var body = ""
	var is_body = false

	var params: Dictionary
	if path.find("?") != -1:
		var path_parts = path.split("?", false, 2)
		path = path_parts[0]
		var query_string = path_parts[1]
		params = {}
		for param in query_string.split("&"):
			var key_value = param.split("=", false, 2)
			if key_value.size() == 2:
				params[key_value[0]] = key_value[1]
	
	for i in range(1, lines.size()):
		if lines[i] == "":
			is_body = true
			continue
		if is_body:
			body += lines[i] + "\n"
		else:
			var header_parts = lines[i].split(": ", false, 2)
			if header_parts.size() == 2:
				headers[header_parts[0]] = header_parts[1]
	
	return {
		"method": method,
		"params": params,
		"path": path,
		"headers": headers,
		"body": body.strip_edges()
	}
# { "method": "GET", "path": "/?code=RbCmAkQirbNsUMI7J345ui9v5PigzT&jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjIxNDE0NTYsImlhdCI6MTc2MjEzNzg1Niwic3ViIjo0fQ.0sv-YZobWduVkx2Q6vI2oeRA6o3_EmgbOCM9CgQPgH4", "headers": { "Host": "localhost:54320", "Connection": "keep-alive", "Upgrade-Insecure-Requests": "1", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36", "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8", "Sec-GPC": "1", "Accept-Language": "en-US,en;q=0.5", "Sec-Fetch-Site": "cross-site", "Sec-Fetch-Mode": "navigate", "Sec-Fetch-User": "?1", "Sec-Fetch-Dest": "document", "sec-ch-ua": "\"Brave\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\"", "sec-ch-ua-mobile": "?0", "sec-ch-ua-platform": "\"Windows\"", "Accept-Encoding": "gzip, deflate, br, zstd", "Cookie": "session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjIxNDE0NTYsImlhdCI6MTc2MjEzNzg1Niwic3ViIjo0fQ.0sv-YZobWduVkx2Q6vI2oeRA6o3_EmgbOCM9CgQPgH4" }, "body": "" }
