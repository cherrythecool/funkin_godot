class_name Character
extends Node2D


const SING_DIRECTIONS: PackedStringArray = ["left", "down", "up", "right"]

@export var strumline: StrumlineManager:
	set(v):
		if strumline != v:
			if is_instance_valid(strumline):
				strumline.note_hit.disconnect(_on_note_hit)
				strumline.note_missed.disconnect(_on_note_missed)

			strumline = v

			if is_instance_valid(strumline):
				strumline.note_hit.connect(_on_note_hit)
				strumline.note_missed.connect(_on_note_missed)

@export_category("Visuals")
@export var icon: HealthIcon = HealthIcon.new()
@export var starts_as_player: bool = false
@export var swap_sing_animations: bool = false

@export_category("Animations")
@export var dances: bool = true
@export var dance_steps: Array[StringName] = [&"idle"]
@export_range(0.0, 1024.0, 0.01) var sing_steps: float = 4.0
var dance_step: int = 0

@export_category("Death")
@export_file("*.tscn") var death_character: String = "uid://w4v0gymuehdt"
@export var gameover_assets: GameoverAssets

@onready var camera_offset: Node2D = $camera_offset
@onready var animation_player: AnimationPlayer = $animation_player

var animation: StringName = &""
var singing: bool = false
var sing_timer: float = 0.0
var in_special_anim: bool = false
var sprite: CanvasItem = null

var swapped_directions: Dictionary[StringName, StringName] = {
	&"left": &"right",
	&"right": &"left",
}

signal animation_played(animation: StringName)
signal animation_finished(animation: StringName)


func _enter_tree() -> void:
	sprite = get_node_or_null(^"sprite")
	animation_player = get_node_or_null(^"animation_player")

	if animation_player != null:
		animation_player.animation_finished.connect(animation_finished.emit)

	dance(true)

	Conductor.beat_hit.connect(_on_beat_hit)


func _process(delta: float) -> void:
	if not singing:
		return
	if not is_instance_valid(Conductor.instance):
		return

	sing_timer += delta / Conductor.instance.beat_delta

	if is_instance_valid(strumline) and singing and (
		StrumlineManager.ReceptorState.HIT in strumline.receptor_states or
		StrumlineManager.ReceptorState.PRESSED in strumline.receptor_states
	):
		return

	if sing_timer * 4.0 >= sing_steps or sing_steps <= 0.0:
		dance(true)


func play_anim(anim: StringName, force: bool = false, special: bool = false) -> void:
	if not is_instance_valid(animation_player):
		push_warning("Failed to play animation in Character without animation_player Node")
		return
	if (in_special_anim and not special) and animation_player.is_playing():
		return
	if not has_anim(anim):
		push_warning("Character missing animation \"%s\"!" % [anim])
		return

	in_special_anim = special
	animation = anim
	singing = animation.begins_with(&"sing_")

	if animation_player.current_animation == anim and force:
		animation_player.seek(0.0)
		animation_player.advance(0.0)
		animation_played.emit(anim)
		return

	animation_player.play(anim)
	animation_played.emit(anim)


func has_anim(anim: StringName) -> bool:
	if not is_instance_valid(animation_player):
		return false

	return animation_player.has_animation(anim)


func dance(force: bool = false) -> void:
	if not dances:
		return
	if singing and not force:
		return
	if dance_steps.is_empty():
		return
	if dance_steps.size() > 1:
		var base: int = dance_step + 1
		if is_instance_valid(Conductor.instance):
			base = floori(Conductor.instance.beat)

		dance_step = wrapi(base, 0, dance_steps.size())
		play_anim(dance_steps[dance_step], force)
		return

	play_anim(dance_steps[0], force)


func set_character_material(new_material: Material) -> void:
	if is_instance_valid(sprite):
		sprite.material = new_material


func get_camera_position() -> Vector2:
	if not is_instance_valid(camera_offset):
		return Vector2.ZERO
	else:
		return camera_offset.global_position


func offset_camera_position(added: Vector2) -> void:
	if not is_instance_valid(camera_offset):
		return

	camera_offset.position += added


func _on_beat_hit(_beat: int) -> void:
	dance()


func _on_note_hit(note: NoteData) -> void:
	if note.state != NoteData.NoteState.ALIVE and sing_timer * 4.0 < 1.0:
		return

	sing_timer = 0.0

	var direction: StringName = SING_DIRECTIONS[note.direction]
	if swap_sing_animations and swapped_directions.has(direction):
		direction = swapped_directions.get(direction)

	play_anim(&"sing_%s" % direction.to_lower(), true)


func _on_note_missed(note: NoteData) -> void:
	sing_timer = 0.0

	var direction: StringName = SING_DIRECTIONS[note.direction]
	if swap_sing_animations and swapped_directions.has(direction):
		direction = swapped_directions.get(direction)

	play_anim(&"sing_%s_miss" % direction.to_lower(), true)
