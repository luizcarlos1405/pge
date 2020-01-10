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
onready var slots = $Parts/Slots

enum SlotSide {LEFT, RIGHT}

export var type: = "None"
export var max_per_node: = 0
export(int, 0, 10) var slots_number: = 1 setget set_slots_number
export var slots_colors: = PoolColorArray() setget set_slots_colors
export var resizable: = true
export var can_be_deleted: = true
export var can_be_moved: = true
export(SlotSide) var slot_side: = SlotSide.RIGHT setget set_slot_side
export(StyleBox) var style_box_normal = preload("PGEBlockPanelNormal.tres")
export(StyleBox) var style_box_focus = preload("PGEBlockPanelFocus.tres")

const Slot: = preload("res://PGEBase/PGESlot/PGESlot.tscn")

var resizing = false

var _reference_position: Vector2


func _ready() -> void:
	set_slots_number(slots_number)
	set_slots_colors(slots_colors)

	if not Engine.editor_hint:
		$PopupMenu.set_item_disabled(1, not can_be_deleted)

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
		1: # Delete
			# TODO: block deletion with undoredo
			queue_free()
			pass
		_:
			push_warning("Nothing implemented for index %s." % index)


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


func connect_to(slot_index: int, pge_node) -> void:
	slots.get_child(slot_index).connect_to(pge_node.slot)


func serialize() -> Dictionary:
	var data: = {
		editor_data = get_editor_data(),
		connections = get_connections(),
		type = type,
		data = get_data()
	}

	return data


func get_connections() -> Array:
	var connections: = []
	for slot in slots.get_children():
		# Blocks slots should have only 1 connection from them
		var edges_from_self: Array = slot.get_edges_from_self()
		if not edges_from_self.empty():
			var edge: PGEEdge = edges_from_self.front()
			if edge:
				connections.append(edge.to_slot.controller.name)
#			else:
#				connections.append("")

	return connections


func refresh_slots_edges() -> void:
	for slot in slots.get_children():
		slot.refresh_edges()


func set_slot_side(value: int) -> void:
	slot_side = value

	# Setters get called before the tree is fully loaded
	if slots:
		if slot_side == SlotSide.LEFT:
			$Parts.move_child(slots, 0)
			for slot in slots.get_children():
				yield(get_tree(), "idle_frame")
				yield(get_tree(), "idle_frame")
				slot.tangent_x_direction = -1

		elif slot_side == SlotSide.RIGHT:
			$Parts.move_child(slots, 1)
			for slot in slots.get_children():
				yield(get_tree(), "idle_frame")
				yield(get_tree(), "idle_frame")
				slot.tangent_x_direction = 1


func set_slots_controller(object: Object) -> void:
	for slot in slots.get_children():
		slot.controller = object


func set_slots_edges_parent_path(node_path: NodePath) -> void:
	for slot in slots.get_children():
		slot.edges_parent_path = node_path

	pass


func set_slots_number(value: int) -> void:
	slots_number = value

	if slots:
		var difference: = slots_number - slots.get_child_count() as int
		if difference > 0:
			for i in range(difference):
				var new_slot: = Slot.instance()
				# The slots owners are not set because of scene inheritance problems
				# So they don't appear in the scene tree of the editor
				slots.add_child(new_slot)
				if slot_side == SlotSide.LEFT:
					new_slot.tangent_x_direction = new_slot.TangentDirection.LEFT
				elif slot_side == SlotSide.RIGHT:
					new_slot.tangent_x_direction = new_slot.TangentDirection.RIGHT


		elif difference < 0:
			var children: Array = slots.get_children()
			for i in range(abs(difference)):
				var child = children.pop_back()
				child.queue_free()


func set_slots_colors(value: PoolColorArray) -> void:
	slots_colors = value

	if slots:
		var slots_to_color: int = min(slots.get_child_count(), slots_colors.size()) as int
		for i in range(slots_to_color):
			slots.get_child(i).color = slots_colors[i]


func get_editor_data() -> Dictionary:
	var data: = {
		name = name,
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