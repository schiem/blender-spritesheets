
@tool
extends EditorImportPlugin


func _get_importer_name():
	return "godot-bss-importer"


func _get_visible_name():
	return "Scene"


func _get_recognized_extensions():
	return ["bss"]


func _get_save_extension():
	return "tscn"


func _get_resource_type():
	return "PackedScene"


func _get_preset_count():
	return 0


func _get_import_options(path, preset):
	var path_without_extension = path.split(".")[0]
	return [
		{name="sheet_image", default_value=path_without_extension + ".png", property_hint=PROPERTY_HINT_FILE, hint_string="*.png", tooltip="Absolute path to the spritesheet .png."},
	]

func _get_priority():
	return 1.0
	
func _get_import_order():
	return 1
	
func _get_option_visibility(path, option_name, options):
	return true

func _import(source_file, save_path, options, platform_variants, gen_files):
	var file := FileAccess.open(source_file, FileAccess.READ)
	var err = file.get_open_error()
	if err != OK:
		printerr("Failed to open file: ", err)
		return FAILED

	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	file.close()

	var framerate = data["frameRate"]
	var time_offset = 1 / framerate
	var texture = load(options["sheet_image"])
	if not texture:
		printerr("Failed to load texture at", options["sheet_image"])
		return FAILED
	var packed_scene = PackedScene.new()
	var scene = Sprite2D.new()
	scene.name = data["name"]
	scene.set_texture(texture)
	scene.set_hframes(texture.get_width() / data["tileWidth"])
	scene.set_vframes(texture.get_height() / data["tileHeight"])
	
	var player = AnimationPlayer.new()
	scene.add_child(player, true)
	player.set_owner(scene)
	
	var library = AnimationLibrary.new()
	player.add_animation_library("sprite_animations", library)

	var count = 0
	for anim_data in data["animations"]:
		var animation = Animation.new()
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, ":frame")

		var time = 0.0
		for i in range(count, anim_data["end"] + 1):
			animation.track_insert_key(track_index, time, i)
			time += time_offset
		count = (anim_data["end"] + 1)
		
		if(anim_data["name"].ends_with("_loop")):
			animation.loop_mode = Animation.LOOP_LINEAR;
		
		# The last frame should be 0 time
		animation.set_length(time - time_offset)
		library.add_animation(anim_data["name"], animation)
		
	err = packed_scene.pack(scene)
	if err != OK:
		printerr("Failed to pack scene: ", err)
		return FAILED

	scene.call_deferred('free')
	var filename = save_path + "." + _get_save_extension()

	err = ResourceSaver.save(packed_scene, filename)
	if err != OK:
		printerr("Failed to save resource: ", err)
		return FAILED
	
	return OK
