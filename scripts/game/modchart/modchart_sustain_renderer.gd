class_name ModchartSustainRenderer extends Object

# so basically, we use fake notes to calculate the modifier
# and then use that position to draw the Line2D
# and finally, we add a tail to the last point of the Line2D and rotate it

var modchart_manager: ModchartManager
var fake_note: Note

func _init(_modchart_manager: ModchartManager) -> void:
	modchart_manager = _modchart_manager
	
	fake_note = load("uid://f75xq2p53bpl").instantiate()
	fake_note.data = NoteData.new()

func draw() -> void:
	for player: int in modchart_manager.note_fields.size():
		var field: NoteField = modchart_manager.note_fields[player]
		
		for note: Note in field.notes:
			if not note.is_sustain:
				continue
			
			if note.clip_rect.visible:
				note.clip_rect.visible = false
				
			var line: Line2D = note.get_node_or_null("modchart_line")
			if line == null:
				line = Line2D.new()
				line.name = "modchart_line"
				
				var orig_tex: Texture2D = note.sustain.texture
				# Extract the texture as a single image
				if orig_tex is AtlasTexture:
					var atlas_img: Image = orig_tex.atlas.get_image()
					var cropped_img: Image = Image.create(orig_tex.region.size.x, orig_tex.region.size.y, false, atlas_img.get_format())
					cropped_img.blit_rect(atlas_img, orig_tex.region, Vector2i.ZERO)
					cropped_img.rotate_90(CLOCKWISE)
					
					line.texture = ImageTexture.create_from_image(cropped_img)
				else:
					line.texture = orig_tex
				
				line.show_behind_parent = true
				line.texture_mode = Line2D.LINE_TEXTURE_TILE
				line.width = note.sustain.size.x * (1 + (1 - note.scale.x))
				line.default_color = Color.WHITE
				line.begin_cap_mode = Line2D.LINE_CAP_BOX
				line.end_cap_mode = Line2D.LINE_CAP_BOX
				
				note.add_child(line)
				
			line.clear_points()
			
			var start_time: float = maxf(note.data.time, Conductor.instance.time)
			var end_time: float = note.data.time + note.data.length
			
			if start_time >= end_time:
				var tail_sprite: Sprite2D = line.get_node_or_null("modchart_tail")
				if tail_sprite != null:
					tail_sprite.visible = false
				return
				
			var duration: float = end_time - start_time
			var segments: int = clampi(int(duration * modchart_manager.sustain_subdivisions * 10.0), 2, 50)
			var points: PackedVector2Array = []
			
			for i: int in range(segments + 1):
				var t: float = float(i) / segments
				var point_time: float = lerp(start_time, end_time, t)
				
				fake_note.data.time = point_time
				fake_note.lane = note.lane
				fake_note.position = field.receptors[note.lane].position
				fake_note.scale = note.scale
				fake_note.rotation = 0
				fake_note.z_index = 0
				
				for mod: ModchartModifier in modchart_manager.modifiers.values():
					mod.get_object(fake_note, field, note.lane, player)
					
				var local_pos: Vector2 = fake_note.position - note.position
				points.append(local_pos)
				
			line.points = points

			var tail: Sprite2D = line.get_node_or_null("modchart_tail")
			if tail == null:
				tail = Sprite2D.new()
				tail.name = "modchart_tail"
				tail.texture = note.tail.texture
				line.add_child(tail)
				
			tail.visible = true
			
			if points.size() >= 2:
				var last_point: Vector2 = points[points.size() - 1]
				var prev_point: Vector2 = points[points.size() - 2]
				
				tail.position = last_point
				var dir: Vector2 = last_point - prev_point
				var angle: float = dir.angle()
				tail.rotation = angle - (PI / 2)
