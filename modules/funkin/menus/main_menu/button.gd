class_name MainMenuButton
extends Control


@export var animation_name: StringName = &'story_mode'
@onready var sprite: AnimatedSprite = $sprite


## This function is triggered when the `menu_accept` action is
## pressed while selecting this button.
func press() -> void:
	pass


## This function is triggered when the delay has passed when
## pressing this menu button.
##
## It returns boolean which specifies whether or not the main
## menu should stop selecting afterwards due to some failure
## in calling the method.
##
## It must be noted that this function is the primary one
## to be used in the main menu and is neccessary for a button
## to function properly in most cases.
func accept() -> bool:
	return false
