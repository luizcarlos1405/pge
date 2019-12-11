extends Panel


export var style_box_normal: StyleBox = preload("GraphStartPanelNormal.tres")
export var style_box_focus: StyleBox = preload("GraphStartPanelFocus.tres")

var first_node_id: String

var _moving: = false


func _ready() -> void:
	connect("gui_input", self, "_on_gui_input")
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _moving:
			move(event.relative)
			pass
		pass

	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_moving = true
			else:
				_moving = false


func get_start_node():
	return $Slot.edges[0].to_slot.controller


func serialize() -> Dictionary:
	var data = {
		editor_data = get_editor_data(),
		first_node_id = get_start_node().name
	}

	return data


func get_editor_data() -> Dictionary:
	var editor_data = {
		rect_global_position = rect_global_position
	}

	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
	rect_position = editor_data.rect_position


func move(ammount: Vector2) -> void:
	rect_position += ammount


func move_to(position: Vector2) -> void:
	rect_position = position


func _on_focus_entered() -> void:
	raise()
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)