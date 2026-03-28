# https://github.com/nebulazorua/andromeda-engine-legacy/blob/master/source/modchart/modifiers/BeatModifier.hx
class_name BeatModifier extends ModchartModifier

func _init() -> void:
	super([])

func _get_shift(obj: Node2D, player: int) -> float:
	var percent = get_value(player)
	if percent == 0:
		return 0.0
		
	var visual_diff: float = 0
	if obj is Note:
		visual_diff = -((Conductor.instance.time - obj.data.time) * 450.0 * Game.instance.scroll_speed)

	var accel_time: float = 0.3 
	var total_time: float = 0.7 

	var beat: float = Conductor.instance.beat + accel_time 
	var even_beat: bool = fmod(beat, 2.0) >= 1.0

	if beat < 0:
		return 0.0 

	beat = fmod(beat, 1.0)
	
	if beat >= total_time:
		return 0.0 

	var amount: float = 0.0
	if beat < accel_time:
		amount = remap(beat, 0, accel_time, 0, 1)
		amount *= amount
	else:
		amount = remap(beat, accel_time, total_time, 1, 0)
		amount = 1.0 - (1.0 - amount) * (1.0 - amount)

	if even_beat:
		amount *= -1.0

	var shift: float = 40.0 * amount * sin((visual_diff / 30.0) + (PI / 2.0))
	return percent * shift

func get_receptor(receptor: Receptor, field: NoteField, player: int) -> void:
	receptor.position.x += _get_shift(receptor, player)

func get_note(note: Note, player: int) -> void:
	note.position.x += _get_shift(note, player)
