extends ModchartAdapter

func get_song_time() -> float:
	return Conductor.instance.time
	
func get_song_step() -> float:
	return Conductor.instance.step

func get_song_beat() -> float:
	return Conductor.instance.beat

func get_player_count() -> int:
	return 2

func get_receptor_direction(receptor:Variant) -> int:
	return receptor.lane

func get_note_direction(note:Variant) -> int:
	return note.lane

func get_receptor_player(receptor:Variant) -> int:
	return 0 if Game.instance.player_field.receptors.has(receptor) else 1

func get_note_player(note:Variant) -> int:
	return 0 if Game.instance.player_field.notes.has(note) else 1

func get_receptors() -> Array[Variant]:
	return Game.instance.player_field.receptors + Game.instance.opponent_field.receptors

func get_notes() -> Array[Variant]:
	return Game.instance.player_field.notes + Game.instance.opponent_field.notes

func get_receptor_sprite(receptor:Variant) -> Node2D:
	return receptor.sprite

func get_note_sprite(note:Variant) -> Node2D:
	return note.sprite
