@tool
class_name TextureAtlasCache
extends Resource


@export var spritemap: Dictionary[StringName, AtlasTexture] = {}
@export var symbols: Dictionary[StringName, TextureAtlasSymbol] = {}
@export var framerate: float = 24.0
@export var stage_symbol: StringName = &""
@export var stage_transform: Transform2D = Transform2D.IDENTITY


static func save_from_atlas(atlas: TextureAtlas) -> void:
	var path := "%s/Animation.res" % atlas.folder

	var cached := TextureAtlasCache.new()
	cached.spritemap = atlas.spritemap
	cached.symbols = atlas.symbols
	cached.framerate = atlas.framerate
	cached.stage_symbol = atlas.stage_symbol
	cached.stage_transform = atlas.stage_transform
	cached.take_over_path(path)

	var flags := ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
	var error := ResourceSaver.save(cached, path, flags)
	if error != OK:
		printerr("Error caching TextureAtlas to path '%s' with error %s!" % [path, error])
	else:
		print("Successfully cached TextureAtlas to path '%s'" % path)


func apply_to_atlas(atlas: TextureAtlas) -> void:
	atlas.spritemap = spritemap
	atlas.symbols = symbols
	atlas.framerate = framerate
	atlas.stage_symbol = stage_symbol
	atlas.stage_transform = stage_transform
