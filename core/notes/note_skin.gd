extends Resource
class_name NoteSkin


@export_group("Receptors", "receptor_")
@export var receptor_frames: SpriteFrames = null
@export var receptor_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var receptor_scale: Vector2 = Vector2.ONE * 0.7

@export_group("Notes", "note_")
@export var note_frames: SpriteFrames = null
@export var note_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var note_scale: Vector2 = Vector2.ONE * 0.7

@export_group("Sustains", "sustain_")
@export_range(0.0, 1.0, 0.001) var sustain_alpha: float = 0.7
@export_range(0.0, 100.0, 1.0, "or_greater") var sustain_size: float = 35.0
@export var sustain_texture_offset: Rect2 = Rect2(0.0, 0.0, 0.0, -2.0)
@export var sustain_tile_texture: bool = false
@export var sustain_tile_mirroring: bool = false

@export_subgroup("Sustain Tails", "sustain_tail_")
@export var sustain_tail_texture_offset: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)
@export_range(0.0, 100.0, 1.0, "or_greater") var sustain_tail_size: float = 35.0
@export var sustain_tail_offset: float = 0.0

@export_group("Note Splashes", "splash_")
@export var splash_frames: SpriteFrames = null
@export var splash_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var splash_scale: Vector2 = Vector2.ONE

@export_subgroup("Note Splash Shader", "splash_shader_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var splash_shader_enabled: bool = false
@export var splash_shader_shader: Shader = null
@export var splash_shader_colors: Array[Color] = [
	Color("c14b99"),
	Color("00ffff"),
	Color("12fa04"),
	Color("f9393f"),
]


func get_receptor_frames() -> SpriteFrames:
	if is_instance_valid(receptor_frames):
		return receptor_frames
	return load("uid://y8en4nx7mbuw")


func get_note_frames() -> SpriteFrames:
	if is_instance_valid(note_frames):
		return note_frames
	return load("uid://b3r2xop0whqyf")


func get_splash_frames() -> SpriteFrames:
	if is_instance_valid(splash_frames):
		return splash_frames
	return load("uid://bw4etux81oui3")


func get_splash_material() -> ShaderMaterial:
	if splash_shader_enabled and is_instance_valid(splash_shader_shader):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = splash_shader_shader
		material.emit_changed()
		return material
	else:
		return null
