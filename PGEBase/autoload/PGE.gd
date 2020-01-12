extends Node
# Deals with selection and UndoRedo operations

signal selection_moved
signal selection_dragged

const SELECTED_GROUP_NAME: = "selected"

var undoredo: = UndoRedo.new()


func select(node: Node) -> void:
	node.add_to_group(SELECTED_GROUP_NAME)
	node.set_selected(true)


func select_only(node: Node) -> void:
	deselect_all()
	select(node)


func select_rect(rect: Rect2, intersecting: = false) -> void:
	for pge_node in get_tree().get_nodes_in_group("pge_node"):
		if intersecting:
			if rect.intersects(pge_node.get_rect()):
				select(pge_node)
		else:
			if rect.encloses(pge_node.get_rect()):
				select(pge_node)


func deselect(node: Node) -> void:
	node.remove_from_group(SELECTED_GROUP_NAME)
	node.set_selected(false)


func deselect_all() -> void:
	for node in get_tree().get_nodes_in_group("selected"):
		deselect(node)


func is_selected(node: Node) -> bool:
	return node.is_in_group(SELECTED_GROUP_NAME)


func toggle_selection(node: Node) -> void:
	if not is_selected(node):
		select(node)
	else:
		deselect(node)
	pass


func move_selection(intended_ammount: Vector2) -> void:
	var selection_rect: Rect2
	var selected_nodes: = get_tree().get_nodes_in_group(SELECTED_GROUP_NAME)
	var pge_nodes: = []

	if not selected_nodes.empty():
		selection_rect = selected_nodes[0].get_rect()

		for node in selected_nodes:
			if node.is_in_group("pge_node"):
				selection_rect = selection_rect.merge(node.get_rect())
				pge_nodes.append(node)

		var target_position: = selection_rect.position + intended_ammount
		if target_position.x < 0:
			target_position.x = 0
		if target_position.y < 0:
			target_position.y = 0

		var ammount: Vector2 = target_position - selection_rect.position
		for pge_node in pge_nodes:
			pge_node.move(ammount)

		emit_signal("selection_dragged", selection_rect)

func undoredo_move_selection(ammount: Vector2) -> void:
	undoredo.create_action("Move Selection")
	for node in get_tree().get_nodes_in_group(SELECTED_GROUP_NAME):
		if node.is_in_group("pge_node"):
			undoredo_move_node(node, node.rect_position - ammount, node.rect_position)

	undoredo.add_do_method(self, "emit_signal", "selection_moved")
	undoredo.add_undo_method(self, "emit_signal", "selection_moved")

	undoredo.commit_action()


func undoredo_delete_selection() -> void:
	undoredo.create_action("Delete Selection")
	for node in get_tree().get_nodes_in_group("selected"):
		var parent: Node = node.get_parent()

		if node.is_in_group("pge_node"):
			undoredo_delete_node(node)
		elif node.is_in_group("pge_block"):
			undoredo_delete_block(node)

	undoredo.commit_action()


func undoredo_add_node(pge_node, parent) -> void:
	select_only(pge_node)
	undoredo.create_action("Add Node")
	undoredo.add_do_reference(pge_node)
	undoredo.add_do_method(parent, "add_child", pge_node, true)
	undoredo.add_undo_method(parent, "remove_child", pge_node)
	undoredo.commit_action()


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
	if not pge_node.can_be_deleted:
		return

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
	undoredo.add_undo_property(pge_block, "rect_min_size", old_rect_min_size)
	undoredo.commit_action()


func undoredo_block_set_slot_side(pge_block, slot_side: int) -> void:
	var old_slot_side: int = pge_block.slot_side

	undoredo.create_action("Set Slot Side")
	undoredo.add_do_method(pge_block, "set_slot_side", slot_side)
	undoredo.add_undo_method(pge_block, "set_slot_side", old_slot_side)
	undoredo.commit_action()


func undoredo_block_set_data(pge_block, old_data: Dictionary, new_data: Dictionary) -> void:
	undoredo.create_action("Block Set Data")
	undoredo.add_do_method(pge_block, "set_data", new_data)
	undoredo.add_undo_method(pge_block, "set_data", old_data)
	undoredo.commit_action()


func undoredo_delete_block(pge_block) -> void:
	if not pge_block.can_be_deleted:
		return

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