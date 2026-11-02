class_name BaseCutscene
extends FunkinScript
## Extension of [FunkinScript] for making cutscenes easier
##
## Generally just a helper class to provide some
## built-ins for making pre-song cutscenes.
## [br][br]
## This class is only a base for other cutscenes
## and their scripts however, so it won't do much
## on its own.


## Whether or not to play this cutscene when opened in freeplay.
## [br][br]
## This node will automatically [code]queue_free()[/code] itself
## if the song is loaded in freeplay but shouldn't play.
@export var play_in_freeplay := false

## Whether this node will [code]queue_free()[/code] itself after the cutscene has finished.
@export var auto_free := true


func _ready() -> void:
	if Game.load_settings[&"mode_name"] == "Freeplay" and not play_in_freeplay:
		queue_free()
		return

	if countdown_container:
		countdown_container.pause_countdown = true


## Call this function to free this node and allow
## the game to start the countdown.
func finish() -> void:
	if countdown_container:
		countdown_container.pause_countdown = false

	if auto_free:
		queue_free()
