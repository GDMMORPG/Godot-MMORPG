@tool
extends RichTextLabel

@export_file("*.yaml") var credits_file: String = "res://CREDITS.yaml"

@export_tool_button("Refresh Credits") var refresh_credits: Callable = _refresh_credits

func _refresh_credits() -> void:
	bbcode_enabled = true
	var credits = load_credits(credits_file)
	display_credits(credits)

func _ready() -> void:
	_refresh_credits()

func load_credits(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open credits file: %s" % file_path)
		return {}
	
	var content = file.get_as_text()
	var credits = YAML.parse(content).get_data()
	return credits

func display_credits(credits: Dictionary) -> void:
	# Clear existing content
	text = ""
	clear()

	# Format:
	# 	Project Name:
	#  		Role:
	#  			Description
	#  			Members:
	#   			- Member Name:
	# 				 github: "GitHub Profile URL"
	# 				 linkedin: "LinkedIn Profile URL"
	# 				 twitter: "Twitter Profile URL"  # Optional
	# 				 website: "Personal Website URL"  # Optional
	for project_name in credits.keys():
		append("[center][b][u]%s[/u][/b][/center]\n" % project_name)
		var project = credits[project_name]
		for role in project.keys():
			var role_info = project[role]
			if role_info == null:
				continue
			if role_info.has("members"):
				append("[center][b]%s[/b][/center]\n" % role)
				for member in role_info["members"]:
					append("\n")
					append("[b]%s[/b] " % member)
					var details = role_info["members"][member]
					if details.has("github"):
						append("[url=%s][img width=24]res://content/socials/Github/github-mark-white.png[/img][/url] " % [details["github"]])
					if details.has("linkedin"):
						append("[url=%s][img width=24]res://content/socials/LinkedIn/LI-In-Bug.png[/img][/url] " % [details["linkedin"]])
					append("\n")  # Add space between members
			append("\n".repeat(10))  # Add space between roles
		append("\n")  # Add space between projects

func append(p_text: String) -> void:
	text += p_text
