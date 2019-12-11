tool
extends PanelContainer

"""
	Can carry data and/or connect to a node.

	It is meant to be instanced by a node and be a child of it. To create a custom
	block just inherit this scene, add nodes as child of `Content` node than extends
	the script by implementing `get_data` and `set_data` methods.

	The value returned by `get_data` will be saved inside the graph resource and will
	be loaded by calling `load_data`.
"""

onready var content: PanelContainer = $Parts/Content
onready var slot = $Parts/PGESlot

enum SlotSide {LEFT, RIGHT}

export var type := "None"
export var max_per_node := 0 #TODO: implement max blocks cap on PGENode
export var slot_active := true setget set_slot_active
export var resizable := true
export var can_be_deleted := true
export(SlotSide) var slot_side := SlotSide.RIGHT setget set_slot_side
export(StyleBox) var style_box_normal = preload("PGEBlockPanelNormal.tres")
export(StyleBox) var style_box_focus = preload("PGEBlockPanelFocus.tres")

var resizing = false

var _reference_position: Vector2


func _ready() -> void:
	slot.set_visible(slot_active)

	if not Engine.editor_hint:
		$Resizer.set_visible(resizable)

		connect("gui_input", self, "_on_gui_input")
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")

		$PopupMenu.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
		$Resizer.connect("gui_input", self, "_on_Resizer_gui_input")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if not get_tree().is_input_handled():
					get_tree().set_input_as_handled()
					$PopupMenu.popup(Rect2(get_global_mouse_position(), Vector2(1, 1)))
					pass


func _on_focus_entered() -> void:
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)


func _on_PopupMenu_index_pressed(index: int) -> void:
	match index:
		0: # Swap slot side
			if slot_side == SlotSide.LEFT:
				set_slot_side(SlotSide.RIGHT)

			elif slot_side == SlotSide.RIGHT:
				set_slot_side(SlotSide.LEFT)
			pass
		1: # Delete
			queue_free()
		_:
			print_debug("[WARNING]: nothing implemented for index %s." % index)


func _on_Resizer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if resizing:
			rect_min_size.y += event.position.y - _reference_position.y
			rect_size.y = rect_min_size.y
			rect_min_size.y = rect_size.y

	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			resizing = event.pressed
			_reference_position = event.position


func connect_to(node) -> void:
	slot.connect_to(node.slot)
	pass


func set_slot_active(value: bool) -> void:
	slot_active = value

	if slot:
		slot.set_visible(value)


func set_slot_side(value: int) -> void:
	slot_side = value

	if slot:
		if slot_side == SlotSide.LEFT:
			$Parts.move_child(slot, 0)
			slot.tangent_x_direction = -1

		elif slot_side == SlotSide.RIGHT:
			$Parts.move_child(slot, 2)
			slot.tangent_x_direction = 1


func serialize() -> Dictionary:
	var connects_to: = ""
	for edge in slot.edges:
		if edge.from_slot == slot:
			connects_to = edge.to_slot.controller.name

	var data: = {
		editor_data = get_editor_data(),
		connects_to = connects_to,
		type = type,
		data = get_data()
	}

	return data


func get_editor_data() -> Dictionary:
	var data: = {
		rect_min_size = rect_min_size,
		filename = filename,
		slot_side = slot_side
	}

	return data


func set_editor_data(data: Dictionary) -> void:
	rect_min_size = data.rect_min_size
	set_slot_side(data.slot_side)


func get_data(): pass
func set_data(data): pass
