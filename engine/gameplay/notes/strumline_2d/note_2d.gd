class_name Note2D
extends Node2D


@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "left,down,up,right") var direction: StringName = &"left"

## Most likely an [AnimatedSprite2D] or [AnimationPlayer].
@export var animated_node: Node

@export_group("Hold", "hold_")

## Inherits from [member animated_node] automatically if not set manually
@export var hold_frames: SpriteFrames

@export var hold_clip: Control
@export var hold_rect: TextureRect
@export var hold_tail: TextureRect

var sustain_offset: float = 0.0
var index: int = 0
var data: NoteData


func _ready() -> void:
	play_animation(&"note")
	update_hold()


func _process(_delta: float) -> void:
	if (not is_instance_valid(data)) or data.state != NoteData.NoteState.HELD:
		return

	hold_clip.modulate.a = data.grace_timer / Conductor.sustain_release_delta


func apply_skin(skin: NoteSkin) -> void:
	if not is_instance_valid(skin):
		return

	texture_filter = skin.note_filter

	if animated_node is AnimatedSprite2D:
		animated_node.sprite_frames = skin.get_note_frames()

	if animated_node is CanvasItem:
		animated_node.scale = skin.note_scale

	hold_clip.size.x = skin.sustain_size
	hold_clip.position.x = -hold_clip.size.x / 2.0

	hold_tail.size.x = skin.sustain_tail_size
	hold_tail.position.x = (hold_clip.size.x - hold_tail.size.x) / 2.0

	hold_frames = skin.get_note_frames()
	update_hold()


func update_hold() -> void:
	if not hold_frames:
		if animated_node is AnimatedSprite2D or animated_node is AnimatedSprite3D:
			hold_frames = animated_node.sprite_frames

	if hold_frames:
		hold_rect.texture = hold_frames.get_frame_texture(&"%s sustain" % direction, 0)
		hold_tail.texture = hold_frames.get_frame_texture(&"%s sustain end" % direction, 0)


func play_animation(anim_name: StringName, force: bool = false) -> void:
	if not animated_node:
		return

	var target_anim := get_full_animation_name(anim_name)

	if "play" in animated_node:
		animated_node.play(target_anim)

	if force:
		if "frame" in animated_node:
			animated_node.frame = 0
		elif "seek" in animated_node:
			animated_node.seek(0.0)


func get_full_animation_name(anim_name: StringName) -> StringName:
	return &"%s%s%s" % [direction, " " if not anim_name.is_empty() else "", anim_name]
