tool
extends PanelContainer


"""
	Should only contain blocks that represent connections and/or data.
"""

signal drag_started
signal dragged
signal drag_ended
signal collapse_toggled(pressed)
signal delete_requested


onready var slot: = $Parts/Menu/PGESlot
onready var collapsed_slot: = $Parts/Menu/CollapsedSlot
onready var header: = $Parts/Header
onready var blocks: = $Parts/Blocks
onready var toggle_collapse: = $Parts/Header/ToggleCollapse
onready var add_block_button: MenuButton = $Parts/Menu/AddBlockButton
onready var name_line_edit: LineEdit = $Parts/Header/Name

enum SlotSide {LEFT, RIGHT}

export(SlotSide) var slot_side: = SlotSide.LEFT setget set_slot_side
export var style_box_normal: StyleBox = preload("PGENodePanelNormal.tres")
export var style_box_focus: StyleBox = preload("PGENodePanelFocus.tres")
export var can_be_deleted: = true setget set_can_be_deleted
export var can_be_renamed: = true

var resizing: = false

var _resize_side: String
var _resize_margin: = 4
var _moving_block = null
var _moving: = false
var _header_pressed: = false
var _move_reference: Vector2
var _default_block_scene_path: = "res://PGEBase/PGEBlock/PGEBlock.tscn"


func _ready() -> void:
	if not Engine.editor_hint:
		slot.controller = self
		connect("gui_input", self, "_on_gui_input")
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")

		$PopupMenu.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
		toggle_collapse.connect("toggled", self, "_on_ToggleCollapse_toggled")
		header.connect("gui_input", self, "_on_Header_gui_input")
		name_line_edit.connect("text_entered", self, "_on_LineEdit_text_entered")
		name_line_edit.connect("focus_exited", self, "_on_LineEdit_focus_exited")
		name_line_edit.text = name

		$Parts.connect("sort_children", self, "_on_Parts_sort_children")
		$Parts/Header/CloseButton.connect("pressed", self, "_on_CloseButton_pressed")

		set_block_options([{text = tr("Block"), scene_path = _default_block_scene_path}])


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.position.x <= _resize_margin:
			set_default_cursor_shape(Control.CURSOR_HSIZE)

		elif event.position.x >= rect_size.x - _resize_margin:
			set_default_cursor_shape(Control.CURSOR_HSIZE)

		elif not resizing:
			set_default_cursor_shape(Control.CURSOR_ARROW)

		if resizing:
			if _resize_side == "left":
				var variation = event.position.x
				var old_x_rect_size = rect_size.x

				if rect_position.x + variation < 0:
					variation -= (rect_position.x + variation)

				rect_size.x -= variation

				if rect_size.x != old_x_rect_size:
					move(Vector2(old_x_rect_size - rect_size.x, 0))

			elif _resize_side == "right":
				var variation = event.position.x - rect_size.x
				rect_size.x += variation

				refresh_blocks_slots()


	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if event.position.x <= _resize_margin:
					resizing = true
					_resize_side = "left"

				elif event.position.x >= rect_size.x - _resize_margin:
					resizing = true
					_resize_side = "right"

			else:
				set_default_cursor_shape(Control.CURSOR_ARROW)
				resizing = false

		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if not get_tree().is_input_handled():
					$PopupMenu.popup(Rect2(get_global_mouse_position(), Vector2(1, 1)))
					pass


func _on_focus_entered() -> void:
	raise()
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)


func _on_PopupMenu_index_pressed(index: int) -> void:
	match index:
		0: # Swap slot side
			var new_side: int

			if slot_side == SlotSide.LEFT:
				new_side = SlotSide.RIGHT
			elif slot_side == SlotSide.RIGHT:
				new_side = SlotSide.LEFT

			PGE.undoredo_node_set_slot_side(self, new_side)
		_:
			push_warning("Nothing implemented for index %s." % index)


func _on_ToggleCollapse_toggled(pressed: bool) -> void:
	PGE.undoredo_node_toggle_collapse(self, pressed)

	grab_focus()


func _on_Header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _header_pressed:
			if not _moving:
				_moving = true
				PGE.undoredo.set_meta("node_start_position", rect_position)

			move(event.position - _move_reference)
			emit_signal("dragged")

	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if not event.doubleclick:
					_header_pressed = true
					_move_reference = event.position
				# Start renaming
				elif can_be_renamed:
					name_line_edit.grab_focus()
					name_line_edit.select_all()
					name_line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				_header_pressed = false
				if _moving:
					_moving = false

					var start_position: Vector2 = PGE.undoredo.get_meta("node_start_position")
					var current_position: = rect_position
					if start_position != current_position:
						PGE.undoredo_move_node(self, start_position, current_position)

						emit_signal("drag_ended")

# Rename
func _on_LineEdit_text_entered(intended_name: String)  -> void:
	if intended_name:
		var old_name: = name
		var new_name: = intended_name
		# So we don't get a name like @PGENode@481, but PGENode2
		name = new_name

		var i: = 2
		while name != new_name:
			new_name = intended_name + i as String
			name = new_name
			i += 1

		PGE.undoredo_rename_node(self, old_name, new_name)

	name_line_edit.release_focus()


func _on_LineEdit_focus_exited() -> void:
	name_line_edit.deselect()
	name_line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_line_edit.text = name


func _on_CloseButton_pressed() -> void:
	PGE.undoredo_delete_node(self)


func _on_pge_block_gui_input(event: InputEvent, block) -> void:
	if event is InputEventMouseMotion:
		if _moving_block:
			var move_to_index = _moving_block.get_index()

			for block in blocks.get_children():
				if not block.can_be_moved: continue

				var block_v_center: float = block.rect_position.y + block.rect_size.y / 2.0

				if block.get_index() < _moving_block.get_index(): # Above moving block
					if blocks.get_local_mouse_position().y < block_v_center:
						move_to_index = block.get_index()
				elif block.get_index() > _moving_block.get_index(): # Bellow moving block
					if blocks.get_local_mouse_position().y > block_v_center:
						move_to_index = block.get_index()

			if move_to_index != _moving_block.get_index():
				blocks.move_child(_moving_block, move_to_index)
				# The change is not instantaneous, so we wait
				yield(get_tree(), "idle_frame")
				yield(get_tree(), "idle_frame")
				refresh_blocks_slots()

	elif event is InputEventMouseButton:
		if not block.resizing and event.button_index == BUTTON_LEFT and not get_tree().is_input_handled():
			if event.pressed:
				if block.can_be_moved:
					block.set_default_cursor_shape(Input.CURSOR_DRAG)
					_moving_block = block

					PGE.undoredo.set_meta("start_index", _moving_block.get_index())

			else:
				if _moving_block:
					var start_index: int = PGE.undoredo.get_meta("start_index")
					var current_index: int = _moving_block.get_index()
					if current_index != start_index:
						PGE.undoredo_move_block(_moving_block, start_index, current_index)

					block.set_default_cursor_shape(Input.CURSOR_ARROW)
					_moving_block = null


func _on_pge_block_resized(block: PanelContainer) -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func _on_pge_block_tree_exited(block: PanelContainer) -> void:
	# Closing the window calls this without a SceneTree
	if is_inside_tree() and get_tree():
		# The change is not instantaneous, so we wait
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")

		refresh_blocks_slots()


func _on_pge_block_data_changed(data: Dictionary) -> void:

	pass


func _on_Parts_sort_children() -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func _on_moved(ammount: Vector2) -> void:
	refresh_slots()
	refresh_blocks_slots()


func refresh_slots() -> void:
	for edge in slot.edges:
		edge.refresh()


func refresh_blocks_slots() -> void:
	for block in blocks.get_children():
		for slot in block.slots.get_children():
			slot.refresh_edges()


func serialize() -> Dictionary:
	var data = {
		editor_data = get_editor_data(),
		blocks = [],
	}

	for pge_block in blocks.get_children():
		var block_data: Dictionary = pge_block.serialize()
		data.blocks.append(block_data)

	return data


func add_block(scene_path: String) -> Node:
	var new_block = load(scene_path).instance()
	blocks.add_child(new_block)
	_initialize_block(new_block)
	return new_block


func _initialize_block(pge_block) -> void:
	pge_block.connect("gui_input", self, "_on_pge_block_gui_input", [pge_block])
	pge_block.connect("tree_exited", self, "_on_pge_block_tree_exited", [pge_block])
	pge_block.connect("tree_exited", add_block_button, "_on_pge_block_tree_exited", [pge_block])
	pge_block.connect("data_changed", self, "_on_block_data_changed", [pge_block])
	pge_block.set_slots_controller(self)
	pge_block.set_slots_edges_parent_path(slot.edges_parent_path)


func move(ammount: Vector2) -> void:
	rect_position += ammount
	refresh_slots()
	refresh_blocks_slots()


func move_to(position: Vector2) -> void:
	rect_position = position
	refresh_slots()
	refresh_blocks_slots()


func collapse() -> void:
	add_block_button.hide()
	collapsed_slot.show()

	# Just... things doesn't happen instantaneously...
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	for block in blocks.get_children():
		block.hide()
		for slot in block.slots.get_children():
			for edge in slot.get_edges_from_self():
				edge.from_slot_overwrite = collapsed_slot
			slot.refresh_edges()


func expand() -> void:
	add_block_button.show()
	collapsed_slot.hide()

	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	for block in blocks.get_children():
		block.show()
		for slot in block.slots.get_children():
			for edge in slot.get_edges_from_self():
				edge.from_slot_overwrite = null
			slot.refresh_edges()


func set_block_options(blocks_data: Array) -> void:
	# Expect an array with Dictionaries in the following format
	# {
	#   text: String,
	#   scene_path: String (The block's res://path/to/block.tsnc)
	# }

	add_block_button.set_block_options(blocks_data)


func get_editor_data() -> Dictionary:
	var editor_data: = {
		name = name,
		rect_position = rect_position,
		rect_size = rect_size,
		slot_side = slot_side,
		filename = filename,
		collapsed = toggle_collapse.pressed,
		can_be_deleted = can_be_deleted,
		can_be_renamed = can_be_renamed
	}

	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
	name_line_edit.text = editor_data.name
	set_name(editor_data.name)
	set_position(editor_data.rect_position - header.rect_size / 2.0)
	set_size(editor_data.rect_size)
	set_slot_side(editor_data.slot_side)
	set_can_be_deleted(editor_data.can_be_deleted)
	can_be_renamed = editor_data.can_be_renamed
	toggle_collapse.pressed = editor_data.collapsed

	if toggle_collapse.pressed:
		collapse()

	name_line_edit.text = name


func set_slot_side(value: int) -> void:
	slot_side = value

	var menu = get_node_or_null("Parts/Menu")
	if menu and slot:
		if slot_side == SlotSide.LEFT:
			menu.move_child(slot, 0)
			menu.move_child(collapsed_slot, 2)

			slot.size_flags_horizontal = Control.SIZE_EXPAND
			collapsed_slot.size_flags_horizontal = Control.SIZE_EXPAND + Control.SIZE_SHRINK_END

			slot.tangent_x_direction = -1
			collapsed_slot.tangent_x_direction = 1

		elif slot_side == SlotSide.RIGHT:
			menu.move_child(slot, 2)
			menu.move_child(collapsed_slot, 0)

			slot.size_flags_horizontal = Control.SIZE_EXPAND + Control.SIZE_SHRINK_END
			collapsed_slot.size_flags_horizontal = Control.SIZE_EXPAND

			slot.tangent_x_direction = 1
			collapsed_slot.tangent_x_direction = -1


func set_can_be_deleted(value: bool) -> void:
	can_be_deleted = value

	$Parts/Header/CloseButton.set_visible(can_be_deleted)