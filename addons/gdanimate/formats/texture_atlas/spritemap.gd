class_name TextureAtlasSpritemap
extends Object


static func load_spritemaps(
	folder: String,
	output_dict: Dictionary[StringName, AtlasTexture],
) -> void:
	var files: PackedStringArray = ResourceLoader.list_directory(folder)
	for file: String in files:
		if not file.begins_with("spritemap"):
			continue
		if not file.get_extension() == "json":
			continue

		load_spritemap(
			"%s/%s" % [
				folder,
				file,
			],
			output_dict
		)


static func load_spritemap(
	path: String,
	output_dict: Dictionary[StringName, AtlasTexture],
) -> void:
	var raw_json: String = FileAccess.get_file_as_string(path)
	var json: Variant = JSON.parse_string(raw_json)
	if json == null:
		printerr("Failed to parse %s as JSON!" % [path])
		return

	if json is not Dictionary:
		printerr("Spritemap JSON must be a Dictionary!")
		return

	json = json as Dictionary

	var metadata: Variant = json.get("meta", {})
	var texture: Texture2D
	if metadata is Dictionary and metadata.has("image"):
		var texture_path: String = "%s/%s" % [
			path.get_base_dir(),
			metadata.get("image"),
		]
		texture_path = ResourceUID.path_to_uid(texture_path)

		texture = load(texture_path)
		if not is_instance_valid(texture):
			printerr("Failed to load %s as Texture2D!" % [texture_path])
			return
	else:
		var texture_path: String = "%s.png" % [path.get_basename()]
		texture_path = ResourceUID.path_to_uid(texture_path)

		texture = load(texture_path)
		if not is_instance_valid(texture):
			printerr("Failed to load %s as Texture2D!" % [texture_path])
			return

	parse(json, output_dict, texture)


static func parse(
	json_data: Dictionary,
	output_dict: Dictionary[StringName, AtlasTexture],
	source_texture: Texture,
) -> void:
	if not json_data.has("ATLAS"):
		printerr("Malformed spritemap JSON has no ATLAS!")
		return

	var data: Dictionary = json_data.get("ATLAS", {})
	var sprites: Array = data.get("SPRITES", [])
	for sprite: Dictionary in sprites:
		var sprite_data: Dictionary = sprite.get("SPRITE", {})

		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source_texture
		atlas_texture.region = Rect2(
			Vector2(
				float(sprite_data.get("x", 0.0)),
				float(sprite_data.get("y", 0.0)),
			),
			Vector2(
				float(sprite_data.get("w", 0.0)),
				float(sprite_data.get("h", 0.0)),
			),
		)
		atlas_texture.set_meta(&"rotated", sprite_data.get("rotated", false))
		atlas_texture.filter_clip = true

		output_dict[StringName(sprite_data.get("name"))] = atlas_texture
