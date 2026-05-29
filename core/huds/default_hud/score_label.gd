extends Label



@export var separator: String = "-"

var game: Game = null


func _ready() -> void:
	game = Game.instance


func _on_hud_setup() -> void:
	if is_instance_valid(game):
		game.score_changed.connect(_on_score_changed)

	update_score_label()


func _on_score_changed(_value: int) -> void:
	update_score_label()


func update_score_label() -> void:
	if not is_instance_valid(game):
		return

	var accuracy_string: String = "N/A"
	if game.rating_calculator.hit_count > 0:
		var decimal_points: int = 2
		if game.accuracy >= 100.0:
			decimal_points = 2
		elif game.accuracy >= 99.9:
			decimal_points = 5
		elif game.accuracy >= 99.0:
			decimal_points = 3

		accuracy_string = "%.*f%%" % [decimal_points, game.accuracy]

	text = "Score:%d %s Misses:%d %s Accuracy:%s (%s)" % [
		game.score,
		separator,
		game.misses,
		separator,
		accuracy_string,
		&"N/A" if accuracy_string == "N/A" else game.rank,
	]
