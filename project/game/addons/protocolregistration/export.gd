@tool
extends EditorExportPlugin

const CustomProtocols := preload("res://addons/protocolregistration/custom_protocols.gd")

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	print("Starting Protocol Registration Export...")
	var directory_path: String = path.get_base_dir()

	var protocols_file_path: String = directory_path + "/protocols"

	if !DirAccess.dir_exists_absolute(protocols_file_path):
		var err: int = DirAccess.make_dir_recursive_absolute(protocols_file_path)
		if err != OK:
			push_error("Failed to create directory: " + protocols_file_path)
			return
	
	# Execute the binaries for each platform to generate protocol registry files
	var my_platform: String = OS.get_name()
	match my_platform:
		"Windows":
			_execute_protocol_registry_generator("res://addons/protocolregistration/bin/protocolregistry.amd64.windows.exe", protocols_file_path)
		"Linux":
			_execute_protocol_registry_generator("res://addons/protocolregistration/bin/protocolregistry.amd64.linux.app", protocols_file_path)
		"macOS":
			_execute_protocol_registry_generator("res://addons/protocolregistration/bin/protocolregistry.amd64.darwin.app", protocols_file_path)
		_:
			push_error("Unsupported platform for protocol registration export: " + my_platform)

func _execute_protocol_registry_generator(executable_path: String, output_dir: String) -> void:
	if not FileAccess.file_exists(executable_path):
		push_error("Protocol registry generator not found: " + executable_path)
		return

	var custom_protocols: CustomProtocols = CustomProtocols.Load()
	if custom_protocols == null:
		return

	var protocols: String = ",".join(custom_protocols.protocols)
	var client_execution_path: String = ProjectSettings.globalize_path("user://bin/auth.exe")

	var output: Array
	var exit_code: int = OS.execute(ProjectSettings.globalize_path(executable_path), ["--register", protocols, client_execution_path, ProjectSettings.globalize_path(output_dir)], output, false, false)
	if exit_code != 0:
		push_error("Protocol registry generator failed with exit code: " + str(exit_code))
	else:
		print("Protocol registry export completed successfully.")
	
	print("Output from protocol registry generator:")
	for line in output:
		print(line)

func _get_name() -> String:
	return "Protocol Registration Exporter"