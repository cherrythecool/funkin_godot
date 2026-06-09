extends Object
class_name ModchartAdapter

func get_song_time() -> float: return 0
func get_song_step() -> float: return 0
func get_song_beat() -> float: return 0

func get_player_count() -> int: return 1
func get_key_count() -> int: return 4

func get_modchart_layer() -> Node: return null

func get_receptor_player(receptor:Variant) -> int: return 0
func get_receptor_direction(receptor:Variant) -> int: return 0

func get_note_player(note:Variant) -> int: return 0
func get_note_direction(note:Variant) -> int: return 0

func get_note_time(note:Variant) -> float: return 0

func get_receptors() -> Array[Variant]: return []
func get_notes() -> Array[Variant]: return []

func get_receptor_sprite(receptor:Variant) -> Node2D: return null
func get_note_sprite(note:Variant) -> Node2D: return null
