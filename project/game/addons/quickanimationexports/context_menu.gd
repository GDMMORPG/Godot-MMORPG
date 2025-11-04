@tool
extends EditorContextMenuPlugin
class_name QuickAnimationExportsContextMenuPlugin

const VALID_EXTENSIONS: Array = ["fbx", "gltf", "glb"]
const LOOPABLE_ANIM_NAMES: Array = ["loop"]

var editor_plugin: EditorPlugin

func _init() -> void:
    pass

func _popup_menu(paths: PackedStringArray) -> void:
    for path in paths:
        if path.get_extension() == "":
            continue # Allow folders...
        if not path.get_extension().to_lower() in VALID_EXTENSIONS:
            return

    add_context_menu_item("Auto Export All Animations", _on_execute)

func _recursive_files(absolute_path: String) -> PackedStringArray:
    var paths: PackedStringArray = []
    var files: Array = DirAccess.get_files_at(absolute_path)
    for file in files:
        var file_path: String = absolute_path + "/" + file
        paths.append(file_path)
    
    var directories: Array = DirAccess.get_directories_at(absolute_path)
    for directory in directories:
        var directory_path: String = absolute_path + "/" + directory
        paths += _recursive_files(directory_path)
    
    return paths

func _on_execute(paths: PackedStringArray) -> void:
    var remove_paths: Array[String] = []
    for path in paths:
        if path.get_extension() != "":
            continue
        remove_paths.append(path)

        var absolute_path: String = ProjectSettings.globalize_path(path)
        # Walk Recursively to find all Valid Extension Files.
        assert(DirAccess.dir_exists_absolute(absolute_path), "Directory does not exist: " + absolute_path)
        var files: Array = _recursive_files(absolute_path)
        for file in files:
            if file.get_extension().to_lower() in VALID_EXTENSIONS:
                paths.append(ProjectSettings.localize_path(file))

    for path in remove_paths:
        paths.remove_at(paths.find(path))
    
    for path: String in paths:
        # Get the Import file.
        var file_without_extension: String = path.get_basename().get_basename()
        var import_filepath: String = path + ".import"

        # Load the FBX file.
        var animation_names: Array[String] = []
        var resource: Resource = load(path)
        assert(resource, "Failed to load Resource: " + path)

        var scene: Node
        if resource is PackedScene:
            var packed_scene: PackedScene = resource
            assert(packed_scene, "Failed to convert Resource to PackedScene: " + path)
            
            scene = packed_scene.instantiate()
            assert(scene, "Failed to instantiate: " + path)
            
            # Get the animations.
            var animation_player: AnimationPlayer
            for child in scene.get_children():
                if child is AnimationPlayer:
                    animation_player = child
                    break
            assert(animation_player, "No AnimationPlayer found in: " + path)
            
            for animation_name: String in animation_player.get_animation_list():
                animation_names.append(animation_name)

        # Load the Importer.
        var import_file = FileAccess.open(import_filepath, FileAccess.READ_WRITE)
        if not import_file:
            if FileAccess.file_exists(import_filepath):
                print("Failed to load Import: ", import_filepath)
            else:
                print("Import file does not exist: ", import_filepath)
            assert(import_file, "Failed to open Import file: " + import_filepath)

        # Parse the Import file.
        var importer_reader: ImporterReader = ImporterReader.new()
        var import_data: Dictionary = importer_reader.parse(import_file.get_as_text())

        assert(import_data.has("params"), "No params found in Import file: " + import_filepath)
        var params: Dictionary = import_data["params"]
        # Disable Mesh data, Texture Data, and Material Data. Only keep Animation Data.
        params["nodes/use_node_type_suffixes"] = false
        params["meshes/ensure_tangents"] = false
        params["meshes/generate_lods"] = false
        params["meshes/create_shadow_meshes"] = false
        params["meshes/light_baking"] = 0
        params["skins/use_named_skins"] = false
        params["fbx/importer"] = 0
        params["fbx/allow_geometry_helper_nodes"] = false
        params["fbx/embedded_image_handling"] = 0
        
        assert(params.has("_subresources"), "No _subresources found in Import file: " + import_filepath)
        var _subresources: Dictionary = params["_subresources"]
            
        for animation_name: String in animation_names:
            
            # Handle the Real Animation Name.
            # If there is only one animation, use the file name.
            # Otherwise, use the animation name.
            var real_animation_name: String = animation_name
            if animation_names.size() == 1:
                real_animation_name = file_without_extension.get_file()
            
            # Handle the Export File Path.
            var export_path: String = path.get_base_dir() + "/" + real_animation_name + ".anim.res"
            
            if not _subresources.has("animations"):
                _subresources["animations"] = {}
            var animations: Dictionary = _subresources["animations"]
            
            if not animations.has(animation_name):
                animations[animation_name] = {}
            var animation: Dictionary = animations[animation_name]

            var loop_mode: Animation.LoopMode = Animation.LoopMode.LOOP_NONE
            for loopable_name: String in LOOPABLE_ANIM_NAMES:
                if loopable_name.to_lower() in real_animation_name.to_lower():
                    loop_mode = Animation.LoopMode.LOOP_LINEAR
                    break
            
            # Manually override/set the save to file and loop mode, automatically.
            animations[animation_name]["save_to_file/enabled"] = true
            animations[animation_name]["save_to_file/path"] = export_path
            animations[animation_name]["settings/loop_mode"] = loop_mode

            print("Exporting Animation: ", animation_name, " to: ", export_path)


        var importer_writer: ImporterWriter = ImporterWriter.new()
        var importer_output: String = importer_writer.write(import_data)

        # Write the Import file.
        # First cleanup the file.
        import_file.seek(0)
        import_file.store_string(importer_output)
        

        import_file.close()

        # Clean-up.
        if scene:
            scene.free()
    
    # Refresh the FileSystem.
    editor_plugin.get_editor_interface().get_resource_filesystem().scan()
    print("Finished Exporting Animations.")
