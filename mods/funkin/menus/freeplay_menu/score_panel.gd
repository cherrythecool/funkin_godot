extends Panel


@export var score_label: Label
@export var misses_label: Label
@export var accuracy_label: Label
@export var rank_label: Label


func refresh(data: Dictionary) -> void:
	score_label.text = "Score: %s" % data.get("score", "N/A")
	misses_label.text = "Misses: %s" % data.get("misses", "N/A")
	rank_label.text = "Rank: %s" % data.get("rank", "N/A")

	if "accuracy" in data and data["accuracy"] is not String:
		accuracy_label.text = "Accuracy: %.5f%%" % data["accuracy"]
	else:
		accuracy_label.text = "Accuracy: N/A"
