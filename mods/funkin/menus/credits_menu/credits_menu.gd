extends Node2D


static var selected: int = 1

@export var music: AudioStreamPlayer
@export var list: Node2D
@export var info_label: Label
@export var info_texture: TextureRect


func _ready() -> void:
	MenuAudio.music.stop()
	music.play()
	change_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&'menu_cancel'):
		music.stop()
		MenuAudio.music.play()
		SceneManager.transition_to_file('uid://b7fwxsepnt38j')

	if event.is_action_pressed(&'menu_accept'):
		var item: ListedAlphabet = list.get_child(selected)
		if item is CreditsContributor:
			OS.shell_open(item.link)

	if event.is_action_pressed(&'menu_up') or event.is_action_pressed(&'menu_down'):
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

	MenuAudio.scroll.play()
