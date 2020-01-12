extends Node


var undoredo: = UndoRedo.new()


func undoredo_add_node(pge_node, parent) -> void:
	undoredo.create_action("Add Node")
	undoredo.add_do_reference(pge_node)
	undoredo.add_do_method(parent, "add_child", pge_node, true)
	undoredo.add_undo_method(parent, "remove_child", pge_node)
	undoredo.commit_action()
	pass


func undoredo_move_node(pge_node, from_position: Vector2, to_position: Vector2) -> void:
	undoredo.create_action("Move Node")
	undoredo.add_do_method(pge_node, "move_to", to_position)
	undoredo.add_undo_method(pge_node, "move_to", from_position)
	undoredo.commit_action()


func undoredo_resize_node(pge_node, old_rect: Rect2, new_rect: Rect2) -> void:
	undoredo.create_action("Resize Node")
	undoredo.add_do_property(pge_node, "rect_position", new_rect.position)
	undoredo.add_do_property(pge_node, "rect_size", new_rect.size)
	undoredo.add_undo_property(pge_node, "rect_position", old_rect.position)
	undoredo.add_undo_property(pge_node, "rect_size", old_rect.size)
	undoredo.commit_action()


func undoredo_rename_node(pge_node, old_name: String, new_name: String) -> void:
	undoredo.create_action("Node Rename")
	undoredo.add_do_property(pge_node, "name", new_name)
	undoredo.add_do_property(pge_node.name_line_edit, "text", new_name)
	undoredo.add_undo_property(pge_node, "name", old_name)
	undoredo.add_undo_property(pge_node.name_line_edit, "text", old_name)
	undoredo.commit_action()


func undoredo_node_set_slot_side(pge_node, slot_side: int) -> void:
	var old_slot_side: int = pge_node.slot_side

	undoredo.create_action("Set Slot Side")
	undoredo.add_do_method(pge_node, "set_slot_side", slot_side)
	undoredo.add_undo_method(pge_node, "set_slot_side", old_slot_side)
	undoredo.commit_action()


func undoredo_node_toggle_collapse(pge_node, collapsed: int) -> void:
	undoredo.create_action("Node Toggle Collapse")
	if collapsed:
		undoredo.add_do_method(pge_node, "collapse")
		undoredo.add_undo_method(pge_node, "expand")
	else:
		undoredo.add_do_method(pge_node, "expand")
		undoredo.add_undo_method(pge_node, "collapse")

	undoredo.commit_action()


func undoredo_delete_node(pge_node) -> void:
	var parent: Node = pge_node.get_parent()

	undoredo.create_action("Delete Node")
	# Connections TO pge_node
	for edge in pge_node.slot.edges:
		if edge.is_inside_tree():
			undoredo.add_undo_reference(edge)
			undoredo.add_do_method(edge.get_parent(), "remove_child", edge)
			undoredo.add_undo_method(edge.get_parent(), "add_child", edge)
	# Connections FROM pge_node
	for block in pge_node.blocks.get_children():
		for slot in block.slots.get_children():
			for edge in slot.edges:
				if edge.is_inside_tree():
					undoredo.add_undo_reference(edge)
					undoredo.add_do_method(edge.get_parent(), "remove_child", edge)
					undoredo.add_undo_method(edge.get_parent(), "add_child", edge)

	undoredo.add_do_method(parent, "remove_child", pge_node)
	undoredo.add_undo_reference(pge_node)
	undoredo.add_undo_method(parent, "add_child", pge_node)

	undoredo.commit_action()


func undoredo_add_block(pge_block, parent: Node) -> void:
	undoredo.create_action("Add Block")
	undoredo.add_do_reference(pge_block)
	undoredo.add_do_method(parent, "add_child", pge_block)
	undoredo.add_undo_method(parent, "remove_child", pge_block)
	undoredo.commit_action()


func undoredo_move_block(pge_block, from_index: int, to_index: int) -> void:
	var parent: Node = pge_block.get_parent()

	undoredo.create_action("Move Block")
	undoredo.add_do_method(parent, "move_child", pge_block, to_index)
	undoredo.add_undo_method(parent, "move_child", pge_block, from_index)
	undoredo.commit_action()


func undoredo_resize_block(pge_block, old_rect_min_size: Vector2, new_rect_min_size: Vector2) -> void:
	undoredo.create_action("Resize Block")
	undoredo.add_do_property(pge_block, "rect_min_size", new_rect_min_size)
#	undoredo.add_do_property(pge_block, "rect_size", new_rect_min_size)
	undoredo.add_undo_property(pge_block, "rect_min_size", old_rect_min_size)
#	undoredo.add_undo_property(pge_block, "rect_size", new_rect_min_size)
	undoredo.commit_action()


func undoredo_block_set_slot_side(pge_block, slot_side: int) -> void:
	var old_slot_side: int = pge_block.slot_side

	undoredo.create_action("Set Slot Side")
	undoredo.add_do_method(pge_block, "set_slot_side", slot_side)
	undoredo.add_undo_method(pge_block, "set_slot_side", old_slot_side)
	undoredo.commit_action()


func undoredo_delete_block(pge_block) -> void:
	var parent: Node = pge_block.get_parent()
	undoredo.create_action("Delete Block")
	undoredo.add_undo_reference(pge_block)
	undoredo.add_do_method(parent, "remove_child", pge_block)
	undoredo.add_undo_method(parent, "add_child", pge_block)

	for edge in pge_block.get_edges():
		undoredo.add_undo_reference(edge)
		undoredo.add_do_method(edge.get_parent(), "remove_child", edge)
		undoredo.add_undo_method(edge.get_parent(), "add_child", edge)

	undoredo.commit_action()
	pass


func undoredo_connect_slots(from_slot, to_slot, pre_created_edge: = null) -> void:
	undoredo.create_action("Connect Slots")
	# It becomes a reference to a freed object once disconnect_to frees this edge
	# I'm not sure if this is needed, but I'll still unreference it, just for sure
	if pre_created_edge:
		undoredo.add_do_reference(pre_created_edge)

	undoredo.add_do_method(from_slot, "connect_to", to_slot, pre_created_edge)
	undoredo.add_undo_method(from_slot, "disconnect_to", to_slot)
	undoredo.commit_action()


func undoredo_remove_edge(edge: PGEEdge) -> void:
	undoredo.create_action("Remove Edge")
	undoredo.add_undo_reference(edge.from_slot)
	undoredo.add_undo_reference(edge.to_slot)
	undoredo.add_do_method(edge.from_slot, "disconnect_to", edge.to_slot)
	undoredo.add_undo_method(edge.from_slot, "connect_to", edge.to_slot)
	undoredo.commit_action()