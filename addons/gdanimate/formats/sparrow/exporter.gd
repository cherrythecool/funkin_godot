@tool
class_name SparrowAtlasExporter
extends Object


static func export(atlas: SparrowAtlas) -> void:
	var state := ExporterState.new()
	state.atlas = atlas

	if atlas.frames.is_empty() or not is_instance_valid(atlas.texture):
		printerr("Cannot export blank or invalid Sparrow atlas!")
		return

	var sprite_frames: SpriteFrames = SpriteFrames.new()
	sprite_frames.remove_animation(&"default")
	if not atlas.symbols.is_empty():
		for symbol: String in atlas.symbols:
			sprite_frames.add_animation(symbol)
			sprite_frames.set_animation_speed(symbol, atlas.framerate)
			sprite_frames.set_animation_loop(symbol, false)
			add_symbol_to_frames(symbol, sprite_frames, state)

	# Equivalent to blank (which means all) on the AnimateSymbol
	sprite_frames.add_animation(&" ")
	sprite_frames.set_animation_speed(&" ", atlas.framerate)
	sprite_frames.set_animation_loop(&" ", false)

	for frame: SparrowFrame in atlas.frames:
		add_frame_to_frames(frame, sprite_frames, " ", state)

	var basename: String = atlas.source_path.get_basename()
	sprite_frames.take_over_path("%s_frames.res" % [basename])
	ResourceSaver.save(
		sprite_frames,
		"%s_frames.res" % [basename],
		(
			ResourceSaver.FLAG_COMPRESS +
			ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
		)
	)


static func add_symbol_to_frames(
	symbol: String,
	sprite_frames: SpriteFrames,
	state: ExporterState,
) -> void:
	var filtered: Array[SparrowFrame] = SparrowFrame.get_filtered_frames(symbol, state.atlas)
	var max_frame_size: Vector2
	for frame: SparrowFrame in filtered:
		if frame.offset.size.x > max_frame_size.x:
			max_frame_size.x = frame.offset.size.x
		if frame.offset.size.y > max_frame_size.y:
			max_frame_size.y = frame.offset.size.y

	for frame: SparrowFrame in filtered:
		# hopefully, this should fix some really weird edge cases
		# with improper frame width and frame heights!!! :3
		if frame.offset.size.x < max_frame_size.x:
			frame.offset.size.x = max_frame_size.x
		if frame.offset.size.y < max_frame_size.y:
			frame.offset.size.y = max_frame_size.y

		add_frame_to_frames(frame, sprite_frames, symbol, state)


static func add_frame_to_frames(
	frame: SparrowFrame,
	sprite_frames: SpriteFrames,
	symbol: String,
	state: ExporterState,
) -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = state.atlas.texture
	atlas_texture.filter_clip = true
	atlas_texture.region = frame.region
	atlas_texture.margin = Rect2(
		-frame.offset.position,
		frame.offset.size - frame.region.size
	)

	if frame.rotated:
		if not state.rotated_cache.has(frame.region):
			# I really wish there was a better way of doing this
			# but as far as I know there isn't one. (Part of the reason
			# sparrow even exists as an option is so I could optimize
			# this out lol)
			if not is_instance_valid(state.image):
				state.image = state.atlas.texture.get_image()

			var rotated: Image = state.image.get_region(frame.region)
			rotated.rotate_90(COUNTERCLOCKWISE)

			atlas_texture.atlas = ImageTexture.create_from_image(rotated)
			atlas_texture.region = Rect2(
				Vector2.ZERO,
				Vector2(frame.region.size.y, frame.region.size.x),
			)
			atlas_texture.margin.size = frame.offset.size - Vector2(frame.region.size.y, frame.region.size.x)
			state.rotated_cache[frame.region] = atlas_texture
		else:
			atlas_texture = state.rotated_cache[frame.region].duplicate()

			# Just in case the frame offset somehow
			# changes even though the frame is the same
			atlas_texture.margin.position = -frame.offset.position

	sprite_frames.add_frame(symbol, atlas_texture)


class ExporterState extends RefCounted:
	var atlas: SparrowAtlas
	var image: Image
	var rotated_cache: Dictionary[Rect2, AtlasTexture]
