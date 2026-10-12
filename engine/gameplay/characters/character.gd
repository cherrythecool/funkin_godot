class_name Character
extends Node2D


@export_group("References")
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

@export var sprite: CanvasItem
@export var animation_player: AnimationPlayer
@export var camera_offset: Node2D

@export_group("Visuals")
@export var icon: HealthIcon = HealthIcon.new()
@export var starts_as_player: bool = false
@export var swap_sing_animations: bool = false

@export_group("Animations")

## An empty string means this charaacter will sing no matter
## the [code].strumline[/code] of any note being hit. If not empty, it
## will only sing when the note being hit has a matching
## [code].strumline[/code] value. (Also applies to missing)
@export var target_strumline_id: StringName = &""

@export var sing_directions: Array[String] = ["left", "down", "up", "right"]
@export var dances: bool = true
@export var dance_steps: Array[StringName] = [&"idle"]
@export_range(0.0, 1024.0, 0.01) var sing_steps: float = 8.0

@export_group("Death")
@export_file("*.tscn") var death_character: String = "uid://w4v0gymuehdt"
@export var gameover_assets: GameoverAssets

var animation: StringName = &""
var dance_step: int = 0
var singing: bool = false
var sing_timer: float = 0.0
var in_special_anim: bool = false

var swapped_directions: Dictionary[StringName, StringName] = {
	&"left": &"right",
	&"right": &"left",
}

signal animation_played(animation: StringName)
signal animation_finished(animation: StringName)


func _enter_tree() -> void:
	if animation_player:
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
	return animation_player and animation_player.has_animation(anim)


func dance(force: bool = false) -> void:
	if (not dances) or (singing and not force) or dance_steps.is_empty():
		return

	var base: int = dance_step + 1
	if Conductor.instance:
		base = floori(Conductor.instance.beat)

	dance_step = wrapi(base, 0, dance_steps.size())
	play_anim(dance_steps[dance_step], force)


func set_character_material(new_material: Material) -> void:
	if is_instance_valid(sprite):
		sprite.material = new_material


func get_camera_position() -> Vector2:
	if not camera_offset:
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
	if (not target_strumline_id.is_empty()) and note.strumline != target_strumline_id:
		return

	sing_timer = 0.0

	var sing_anim := &""
	var type := note.type_data
	if type.get(&"use_custom_sing", false):
		sing_anim = type.get(&"custom_sing", &"")
	else:
		var direction := StringName(sing_directions[note.direction % sing_directions.size()])
		if swap_sing_animations and swapped_directions.has(direction):
			direction = swapped_directions.get(direction)

		sing_anim = direction

	sing_anim = type.get(&"sing_prefix", &"") + sing_anim + type.get(&"sing_suffix", &"")
	play_anim(sing_anim, true)


func _on_note_missed(note: NoteData) -> void:
	if (not target_strumline_id.is_empty()) and note.strumline != target_strumline_id:
		return

	sing_timer = 0.0

	var sing_anim := &""
	var type := note.type_data
	if type.get(&"use_custom_miss", false):
		sing_anim = type.get(&"custom_miss", &"")
	else:
		var direction := StringName(sing_directions[note.direction % sing_directions.size()])
		if swap_sing_animations and swapped_directions.has(direction):
			direction = swapped_directions.get(direction)

		sing_anim = direction

	sing_anim = type.get(&"miss_prefix", &"") + sing_anim + type.get(&"miss_suffix", &"")
	play_anim(sing_anim, true)
