## Extension of [FunkinScript] for making cutscenes.
##
## General helper class to provide some helpful
## built-ins for making song cutscenes.
## This class is only a base for other cutscenes
## and their scripts however, so it won't do much
## on its own.
class_name BaseCutscene extends FunkinScript


## Defines whether or not to play this cutscene when opened in freeplay.
## [br][br]It will automatically queue free the base node upon
## loading the script through a song in freeplay.
@export var play_in_freeplay: bool = false

## Whether to free the cutscene after its done playing.
@export var auto_free: bool = true

func _ready() -> void:
	if Game.load_settings[&"mode_name"] == "Freeplay" and not play_in_freeplay:
		queue_free()
		return
	game.hud.pause_countdown = true


## Call this function to free this node and allow
## the game to start the countdown.
func finish() -> void:
	game.hud.pause_countdown = false
	if auto_free:
		queue_free()
