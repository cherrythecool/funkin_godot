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


func get_collective_score(songs: Array[StringName], difficulty: StringName) -> Dictionary:
	var total_score := 0
	var total_misses := 0
	var had_score := false

	for song_name: StringName in songs:
		if not has_score(song_name, difficulty):
			continue
		else:
			had_score = true

		var high_score := Highscores.get_score(song_name, difficulty)
		total_score += int(high_score.get("score", 0))
		total_misses += int(high_score.get("misses", 0))

	if had_score:
		return {
			"score": total_score,
			"misses": total_misses,
		}
	else:
		return {
			"score": "N/A",
			"misses": "N/A",
		}


func _get_score_key(song: StringName, difficulty: StringName) -> String:
	return "%s/%s" % [song, difficulty]
