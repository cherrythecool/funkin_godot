class_name Receptor2D
extends Node2D


signal animation_finished(anim_name: StringName)

@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "left,down,up,right") var direction: StringName = &"left"

@export_group("Animation")

@export var sprite: AnimatedSprite2D

@export var splash: AnimatedSprite2D
@export var splash_variations: int = 2

## Most likely an [AnimatedSprite2D] or [AnimationPlayer].
@export var animated_node: Node:
	set = _set_animated_node

## If the current [member direction] has a key-value pair here, then that
## string is appended to the beginning of the animation name that is played
## for this receptor. [br][br]
## For example, playing the [code]static[/code] animation on a
## receptor with a prefix of [code]left/[/code] would play the animation
## [code]left/static[/code] on the current [member animated_node] (if it exists).
@export var animation_prefixes: Dictionary[StringName, String] = {
	&"left": "left/",
	&"down": "down/",
	&"up": "up/",
	&"right": "right/",
}

@export var animation_names: Dictionary[StrumlineManager.ReceptorState, StringName] = {
	StrumlineManager.ReceptorState.RELEASED: &"static",
	StrumlineManager.ReceptorState.PRESSED: &"press",
	StrumlineManager.ReceptorState.HIT: &"confirm",
}

var notes: Array[Note2D] = []
var last_played_anim: StringName = &""
var hold_timer: float = 0.0


func _ready() -> void:
	play_animation(&"static")


func _process(delta: float) -> void:
	hold_timer += delta


func apply_skin(skin: NoteSkin) -> void:
	if not is_instance_valid(skin):
		return

	if sprite:
		sprite.texture_filter = skin.receptor_filter
		sprite.scale = skin.receptor_scale
		sprite.sprite_frames = skin.get_receptor_frames()

	if splash:
		splash.texture_filter = skin.splash_filter
		splash.scale = skin.splash_scale
		splash.material = skin.get_splash_material()
		splash.sprite_frames = skin.get_splash_frames()


func play_splash() -> void:
	if (not splash) or splash_variations < 1:
		return

	splash.play(&"%s_%d" % [direction, randi_range(1, splash_variations)])
	splash.frame = 0
	splash.show()


func play_animation(anim_name: StringName, force: bool = false) -> void:
	last_played_anim = anim_name

	if not animated_node:
		return

	var target_anim := get_full_animation_name(anim_name)

	if "play" in animated_node:
		animated_node.play(target_anim)

	if "advance" in animated_node:
		animated_node.advance(0.0)

	if force:
		if "frame" in animated_node:
			animated_node.frame = 0
		elif "seek" in animated_node:
			animated_node.seek(0.0)


func get_full_animation_name(anim_name: StringName) -> StringName:
	if animation_prefixes.has(direction):
		return animation_prefixes[direction] + anim_name
	else:
		return anim_name


func get_animation_from_state(state: StrumlineManager.ReceptorState) -> StringName:
	if animation_names.has(state):
		return animation_names[state]
	else:
		return &""


func is_playing() -> bool:
	if "playing" in animated_node:
		return animated_node.playing
	elif "current_animation" in animated_node:
		return animated_node.current_animation != &""
	else:
		return false


func _set_animated_node(new_node: Node) -> void:
	if animated_node:
		if animated_node is AnimationPlayer:
			animated_node.animation_finished.disconnect(animation_finished.emit)
		elif "animation_finished" in animated_node:
			animated_node.animation_finished.disconnect(_on_animation_finished)

	animated_node = new_node

	if animated_node:
		if animated_node is AnimationPlayer:
			animated_node.animation_finished.connect(animation_finished.emit)
		elif "animation_finished" in animated_node:
			animated_node.animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	animation_finished.emit(last_played_anim)
