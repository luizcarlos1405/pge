tool
extends PanelContainer


"""
	Should only contain blocks that represent connections and/or data.
"""


signal moved
signal released

onready var slot: = $Parts/Menu/PGESlot
onready var header: = $Parts/Header
onready var blocks: = $Parts/Blocks
onready var add_block_popup: PopupMenu = $Parts/Menu/AddBlockButton.get_popup()
onready var name_label: Label = $Parts/Header/Name

enum SlotSide {LEFT, RIGHT}

export(SlotSide) var slot_side: = SlotSide.LEFT setget set_slot_side
export var style_box_normal: StyleBox = preload("PGENodePanelNormal.tres")
export var style_box_focus: StyleBox = preload("PGENodePanelFocus.tres")
export var can_be_deleted := true

var block_counter := {}
var resizing := false

var _resize_side: String
var _resize_margin := 4
var _moving_block = null
var _moving: = false
var _resize_reference: Vector2
var _move_reference: Vector2
var _default_block_packed_scene = load("res://PGEBase/PGEBlock/PGEBlock.tscn")


func _ready() -> void:
	if not Engine.editor_hint:
		slot.controller = self
		connect("gui_input", self, "_on_gui_input")
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")

		$PopupMenu.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
		header.connect("gui_input", self, "_on_Header_gui_input")
		name_label.connect("text_entered", self, "_on_LineEdit_text_entered")
		name_label.connect("focus_exited", self, "_on_LineEdit_focus_exited")
		name_label.text = name

		$Parts.connect("sort_children", self, "_on_Parts_sort_children")
		$Parts/Header/CloseButton.connect("pressed", self, "_on_CloseButton_pressed")

		connect("moved", self, "_on_moved")

		set_block_options([{text = "Block", metadata = _default_block_packed_scene}])


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.position.x <= _resize_margin:
			set_default_cursor_shape(Control.CURSOR_HSIZE)

		elif event.position.x >= rect_size.x - _resize_margin:
			set_default_cursor_shape(Control.CURSOR_HSIZE)

		elif not resizing:
			set_default_cursor_shape(Control.CURSOR_ARROW)

		if resizing:
			var variation = event.global_position.x - _resize_reference.x
			if _resize_side == "left":
				var old_x_rect_size = rect_size.x

				if rect_position.x + variation < 0:
					variation -= (rect_position.x + variation)

				rect_size.x -= variation

				if rect_size.x != old_x_rect_size:
					move(Vector2(old_x_rect_size - rect_size.x, 0))

				_resize_reference = rect_position

			elif _resize_side == "right":
				rect_size.x += variation

				_resize_reference = rect_position + rect_size


	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if not get_tree().is_input_handled():
					$PopupMenu.popup(Rect2(get_global_mouse_position(), Vector2(1, 1)))
					pass

		elif event.button_index == BUTTON_LEFT:
			if event.pressed:
				_resize_reference = event.global_position

				if event.position.x <= _resize_margin:
					resizing = true
					_resize_side = "left"

				elif event.position.x >= rect_size.x - _resize_margin:
					resizing = true
					_resize_side = "right"

			else:
				set_default_cursor_shape(Control.CURSOR_ARROW)
				resizing = false


func _on_focus_entered() -> void:
	raise()
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)



func _on_PopupMenu_index_pressed(index: int) -> void:
	match index:
		0:
			if slot_side == SlotSide.LEFT:
				set_slot_side(SlotSide.RIGHT)

			elif slot_side == SlotSide.RIGHT:
				set_slot_side(SlotSide.LEFT)
		_:
			print_debug("[WARNING]: nothing implemented for index %s." % index)


func _on_Header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _moving:
			move(event.position - _move_reference)

	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if not event.doubleclick:
					_moving = true
					_move_reference = event.position
				# Rename
				else:
					name_label.grab_focus()
					name_label.select_all()
					name_label.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				_moving = false
				emit_signal("released")

# Rename
func _on_LineEdit_text_entered(new_name: String)  -> void:
	name_label.release_focus()

	if new_name:
		name = new_name
		# Little hack to avoid the @ on the autorenaming of godot
		var i: = 1
		var intended_name: = new_name
		while name != new_name as String:
			i += 1
			new_name = intended_name + i as String
			name = new_name

		name_label.text = name


func _on_LineEdit_focus_exited() -> void:
	name_label.deselect()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = name


func _on_CloseButton_pressed() -> void:
	queue_free()


func _on_block_gui_input(event: InputEvent, block) -> void:
	if event is InputEventMouseMotion:
		# FIXME: When moving a smaller block through a larger one, they start swapping fast
		if _moving_block:
			var move_to_index = 0

			for block in blocks.get_children():
				if blocks.get_local_mouse_position().y > block.rect_position.y:
					move_to_index = block.get_index()
				pass

			if move_to_index != _moving_block.get_index():
				blocks.move_child(_moving_block, move_to_index)

	elif event is InputEventMouseButton:
		if not block.resizing and event.button_index == BUTTON_LEFT and not get_tree().is_input_handled():
			if event.pressed:
				block.set_default_cursor_shape(Input.CURSOR_DRAG)
				_moving_block = block

			else:
				block.set_default_cursor_shape(Input.CURSOR_ARROW)
				_moving_block = null


func _on_block_resized(block: PanelContainer) -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func _on_block_tree_exiting(block) -> void:
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2

	if block_counter.has(block.type):
		block_counter[block.type].count -= 1
		add_block_popup.set_block_disabled(block_counter[block.type].popup_menu_id, false)


func _on_Parts_sort_children() -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func _on_moved() -> void:
	for edge in slot.edges:
		edge.refresh()

	for block in blocks.get_children():
		for edge in block.slot.edges:
			edge.refresh()


func serialize() -> Dictionary:
	var data = {
		editor_data = get_editor_data(),
		blocks = [],
	}

	for pge_block in blocks.get_children():
		var block_data: Dictionary = pge_block.serialize()
		data.blocks.append(block_data)

	return data


func add_block(packed_scene: PackedScene) -> Node:
	var new_block = packed_scene.instance()
	blocks.add_child(new_block)

	new_block.connect("gui_input", self, "_on_block_gui_input", [new_block])
	new_block.connect("tree_exiting", self, "_on_block_tree_exiting", [new_block])
	new_block.slot.controller = self
	new_block.slot.edges_parent_path = slot.edges_parent_path

	return new_block


func move(ammount: Vector2) -> void:
	rect_position += ammount
	emit_signal("moved")


func move_to(position: Vector2) -> void:
	rect_position = position
	emit_signal("moved")
	emit_signal("released")


func set_block_options(blocks_data: Array) -> void:
	# Expect an array with Dictionaries in the following format
	# {
	#   text: String,
	#   metadata: PackedScene (The block's load(path_to.tsnc))
	# }

	add_block_popup.clear()

	for i in range(blocks_data.size()):
		var data = blocks_data[i]
		add_block_popup.add_item(data.text)
		add_block_popup.set_item_metadata(i, data.metadata)


func get_editor_data() -> Dictionary:
	var editor_data := {
		name = name,
		rect_position = rect_position,
		rect_size = rect_size,
		slot_side = slot_side,
		filename = filename
	}

	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
	name_label.text = editor_data.name
	set_name(editor_data.name)
	set_position(editor_data.rect_position)
	set_size(editor_data.rect_size)
	set_slot_side(editor_data.slot_side)

	name_label.text = name


func set_slot_side(value: int) -> void:
	slot_side = value

	var menu = get_node_or_null("Parts/Menu")
	if menu and slot:
		if slot_side == SlotSide.LEFT:
			menu.move_child(slot, 0)
			slot.tangent_x_direction = -1

		elif slot_side == SlotSide.RIGHT:
			menu.move_child(slot, 1)
			slot.tangent_x_direction = 1