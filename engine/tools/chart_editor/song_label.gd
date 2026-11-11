extends Label


@export var chart_editor: Node


func _ready() -> void:
	if chart_editor:
		chart_editor.chart_loaded.connect(_on_chart_loaded)


func _on_chart_loaded() -> void:
	if not chart_editor:
		text = "??? - ???"
		return

	text = "%s - %s" % [chart_editor.metadata.get_full_name(), chart_editor.difficulty.capitalize()]
	tooltip_text = "%s\n%s\n%s" % [chart_editor.song_name, chart_editor.difficulty, chart_editor.songs_folder]
