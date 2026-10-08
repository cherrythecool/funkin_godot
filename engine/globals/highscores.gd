extends Node


var data: Dictionary


func _ready() -> void:
	SaveData.set_default_save(&"scores", {"scores": {}})
	SaveData.load_save(&"scores")


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
