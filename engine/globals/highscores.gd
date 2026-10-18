extends Node


var data: Dictionary


func _ready() -> void:
	SaveData.set_default_save(&"scores", {"scores": {}})
	SaveData.load_save(&"scores")

	var scores: Dictionary = SaveData.get_save_value(&"scores", "scores")
	for key: String in scores:
		if scores[key]["score"] is String and scores[key]["score"] == "N/A":
			continue

		# thanks json parser
		scores[key]["score"] = int(scores[key]["score"])
		scores[key]["misses"] = int(scores[key]["misses"])

	SaveData.set_save_value(&"scores", "scores", scores, false)


func get_score(song: StringName, difficulty: StringName) -> Dictionary:
	return SaveData.get_save_value(&"scores", "scores").get(_get_score_key(song, difficulty), {
		"score": "N/A",
		"misses": "N/A",
		"accuracy": "N/A",
		"rank": "N/A",
	})


func has_score(song: StringName, difficulty: StringName) -> bool:
	return SaveData.get_save_value(&"scores", "scores").has(_get_score_key(song, difficulty))


func set_score(song: StringName, difficulty: StringName, score: Dictionary) -> void:
	var scores: Dictionary = SaveData.get_save_value(&"scores", "scores")
	scores[_get_score_key(song, difficulty)] = score
	SaveData.set_save_value(&"scores", "scores", scores)


func reset_score(song: StringName, difficulty: StringName) -> void:
	var scores: Dictionary = SaveData.get_save_value(&"scores", "scores")
	scores.erase(_get_score_key(song, difficulty))
	SaveData.set_save_value(&"scores", "scores", scores)


func _get_score_key(song: StringName, difficulty: StringName) -> String:
	return "%s/%s" % [song, difficulty]
