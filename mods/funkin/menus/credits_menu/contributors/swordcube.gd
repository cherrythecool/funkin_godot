@tool
extends CreditsContributor


@export var texture_rect: TextureRect
@export var label: Label

var starting_stretch_mode: TextureRect.StretchMode
var starting_texture_filter: CanvasItem.TextureFilter
var last_target: int = -1
var check_physics: bool = false
var timer: float = 0.0


func _ready() -> void:
	starting_stretch_mode = texture_rect.stretch_mode
	starting_texture_filter = texture_rect.texture_filter


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if check_physics:
		if target_y == 0:
			timer += delta

			if timer >= 1.0 / 24.0:
				timer = 0.0

				var extra: TextureRect = texture_rect.duplicate()
				extra.material = load("uid://h6uy4lto3tyx")
				extra.modulate.a = 1.0
				texture_rect.add_sibling(extra)
				texture_rect.move_to_front()

				var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel()
				tween.tween_property(extra, ^"modulate:a", 0.0, 0.75)
				tween.tween_property(extra, ^"offset_transform_position:x", randf_range(-25.0, 25.0), 1.0)
				tween.tween_property(extra, ^"offset_transform_position:y", randf_range(-25.0, 25.0), 1.0)
				tween.tween_property(extra, ^"offset_transform_scale", Vector2.ONE * randf_range(1.1, 1.3), 0.5)
				tween.tween_callback(extra.queue_free).set_delay(0.5)

			texture_rect.position = (
				Vector2(16.0, 64.0) +
				Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
			)
		else:
			texture_rect.position = Vector2(16.0, 64.0)
			check_physics = false


func _process(delta: float) -> void:
	super(delta)

	if Engine.is_editor_hint():
		return

	if last_target != target_y:
		last_target = target_y
		check_physics = true

		if target_y == 0:
			label.material = material
			texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
			texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			label.material = null
			texture_rect.stretch_mode = starting_stretch_mode
			texture_rect.texture_filter = starting_texture_filter
