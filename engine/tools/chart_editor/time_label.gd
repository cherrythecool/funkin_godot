extends Label


func _process(_delta: float) -> void:
	text = "%s%s.%03ds, %.2f Measures, %.2f Beats, %.2f Steps" % [
		"-" if Conductor.time < 0.0 else "",
		FunkinUtils.format_time(Conductor.time),
		absi(roundi((Conductor.time - int(Conductor.time)) * 1000.0)),
		Conductor.measure,
		Conductor.beat,
		Conductor.step,
	]
