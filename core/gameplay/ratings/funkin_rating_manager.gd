class_name FunkinRatingManager
extends RatingManager


@export_group("Game Over", "gameover_")
@export_file("*.tscn") var gameover_file_path: String = "uid://c05dah5aarqg8"

@export_subgroup("Is FunkinGameOver", "gameover_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var gameover_set_default_values := true
@export var gameover_set_character_position := true
@export var gameover_set_character_path := true
@export var gameover_keep_camera_transform := true

@export var ranks: Dictionary[float, StringName] = {
	0.0: &"F",
	60.0: &"D",
	70.0: &"C",
	80.0: &"B",
	90.0: &"A",
	99.0: &"S",
	100.0: &"S+",
}

@export var ratings: Array[FunkinRating] = []
@export var miss_rating: FunkinRating = null

var score := 0
var misses := 0
var combo := 0
var health := 50.0

var _accumulated_accuracy := 0.0
var _total_notes_hit := 0


func _ready() -> void:
	if Game.instance:
		Game.instance.song_finished.connect(_on_song_finished)


func get_health_percent() -> float:
	return health


func add_note_hit(time_diff: float) -> void:
	_total_notes_hit += 1
	combo += 1

	var rating := get_rating(time_diff)
	if rating:
		_apply_rating(rating)

	changed.emit()


func add_note_miss() -> void:
	_total_notes_hit += 1
	combo = 0

	if miss_rating:
		_apply_rating(miss_rating)

	changed.emit()


func _died() -> void:
	var game := Game.instance
	if gameover_set_default_values and game:
		if gameover_set_character_position and game.player:
			FunkinGameOver.character_position = game.player.global_position

		if gameover_set_character_path and game.player:
			FunkinGameOver.character_path = game.player.death_character

		game.persist_camera_on_exit = gameover_keep_camera_transform

	SceneManager.swap_to_file(gameover_file_path)


func get_accuracy() -> float:
	if _total_notes_hit <= 0:
		return 0.0
	else:
		return (_accumulated_accuracy / float(_total_notes_hit)) * 100.0


func get_rank() -> StringName:
	var value := &"N/A"
	var current_accuracy := get_accuracy()
	for accuracy_minimum: float in ranks:
		if current_accuracy >= accuracy_minimum:
			value = ranks[accuracy_minimum]
		else:
			break

	return value


func get_rating(time_diff: float) -> FunkinRating:
	if ratings.is_empty():
		return null

	var returned_rating := ratings[0]
	for rating: FunkinRating in ratings:
		if time_diff <= rating.threshold_millis / 1000.0:
			returned_rating = rating
		else:
			break

	return returned_rating


func _apply_rating(rating: FunkinRating) -> void:
	score += rating.score
	health = clampf(health + rating.health_percent, 0.0, 100.0)
	_accumulated_accuracy += rating.accuracy_percent / 100.0


func _on_song_finished() -> void:
	var song: StringName = Game.load_settings[&"song_name"]
	var difficulty: StringName = Game.load_settings[&"song_difficulty"]

	var current_score: Dictionary = Scores.get_score(song, difficulty)
	if (not Scores.has_score(song, difficulty)) or score > current_score["score"]:
		Scores.set_score(song, difficulty, {
			"score": score,
			"misses": misses,
			"accuracy": get_accuracy(),
			"rank": get_rank(),
		})
