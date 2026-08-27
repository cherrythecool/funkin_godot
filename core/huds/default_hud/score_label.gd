extends Label



@export var separator: String = "-"

var rating_manager: RatingManager


func _ready() -> void:
	rating_manager = get_tree().get_first_node_in_group(&"RatingManager")

	if rating_manager:
		rating_manager.changed.connect(update_score_label)


func _on_hud_setup() -> void:
	update_score_label()


func update_score_label() -> void:
	if (not rating_manager) or (rating_manager is not FunkinRatingManager):
		return

	var accuracy_string: String = "N/A"
	if rating_manager._total_notes_hit > 0:
		var decimal_points := 2
		if rating_manager.get_accuracy() >= 100.0:
			decimal_points = 2
		elif rating_manager.get_accuracy() >= 99.9:
			decimal_points = 5
		elif rating_manager.get_accuracy() >= 99.0:
			decimal_points = 3

		accuracy_string = "%.*f%%" % [
			decimal_points,
			floorf(rating_manager.get_accuracy() * 100000.0) / 100000.0,
		]

	text = "Score:%d %s Misses:%d %s Accuracy:%s (%s)" % [
		rating_manager.score,
		separator,
		rating_manager.misses,
		separator,
		accuracy_string,
		&"N/A" if accuracy_string == "N/A" else rating_manager.get_rank(),
	]
