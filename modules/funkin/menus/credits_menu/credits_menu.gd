extends Node2D



@onready var list: Node2D = %list
@onready var info_label: Label = %label
@onready var info_texture: TextureRect = %texture
@onready var music: AudioStreamPlayer = %music

static var selected: int = 1


func _ready() -> void:
	GlobalAudio.music.stop()
	music.play()
	change_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return

	if event.is_action(&'menu_cancel'):
		music.stop()
		GlobalAudio.music.play()
		SceneManager.transition_to_packed(load('uid://b7fwxsepnt38j'))
	if event.is_action(&'menu_accept'):
		var item: ListedAlphabet = list.get_child(selected)
		if item is CreditsContributor:
			OS.shell_open(item.link)
	if event.is_action(&'menu_up') or event.is_action(&'menu_down'):
		change_selection(roundi(Input.get_axis(&'menu_up', &'menu_down')))


func change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, list.get_child_count())
	for i: int in list.get_child_count():
		var item: ListedAlphabet = list.get_child(i)
		item.target_y = i - selected
		if item.scale == Vector2.ONE:
			item.modulate.a = 0.6 + (float(item.target_y == 0) * 0.4)
		else:
			item.modulate.a = 1.0

	var selected_item: ListedAlphabet = list.get_child(selected)
	if selected_item is CreditsContributor:
		info_label.text = selected_item.role
		info_texture.texture = selected_item.texture

	if amount == 0:
		return

	if selected_item.text.is_empty() or selected_item.scale != Vector2.ONE:
		change_selection(signi(amount))
		return

	GlobalAudio.get_player(^"MENU/SCROLL").play()
