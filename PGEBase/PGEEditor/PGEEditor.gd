extends Control

"""
	Graphical editor for a PGEGraph.
"""

signal graph_loaded

export(GDScript) var graph_class: GDScript
export(PackedScene) var pge_node_packed_scene = preload("../PGENode/PGENode.tscn")

const SAVE_KEY = KEY_S
const LOAD_KEY = KEY_L
const EXPORT_KEY = KEY_E
const ADD_NODE_KEY = KEY_A
const NEW_GRAPH_NAME: = "Untitled"

var panel_margin: = 500

var _popup_titles = {
	"save": tr("Save Graph"),
	"load": tr("Load Graph"),
	"export": tr("Export Graph")
}

var _zoom_step: = 0.1
var _zoom_min: = 0.2
var _zoom_max: = 5.0

onready var scroll_container = $ScrollContainer
onready var panel = $ScrollContainer/Panel
onready var graph_name = $Header/Items/GraphName
onready var nodes = $ScrollContainer/Panel/Nodes
onready var edges = $ScrollContainer/Panel/Edges
onready var _scroll_container_initial_size = scroll_container.rect_size
onready var _graph: PGEGraph = graph_class.new()


func _ready():
	graph_name.text = NEW_GRAPH_NAME

	panel.rect_min_size.x = OS.window_size.x
	panel.rect_min_size.y = OS.window_size.y - $Header.rect_size.y
	refresh_panel_size()

	panel.connect("gui_input", self, "_on_Panel_gui_input")

	$FileDialog.connect("file_selected", self, "_on_FileDialog_file_selected")
	$FileDialog.connect("visibility_changed", self, "_on_FileDialog_visibility_changed")

	$Header/Items/SaveButton.connect("pressed", self, "_on_SaveButton_pressed")
	$Header/Items/LoadButton.connect("pressed", self, "_on_LoadButton_pressed")
	$Header/Items/ExportButton.connect("pressed", self, "_on_ExportButton_pressed")
	$Header/Items/AddNodeButton.connect("pressed", self, "_on_AddNodeButton_pressed")
	$Header/Items/ZoomIn.connect("pressed", self, "_on_ZoomIn_pressed")
	$Header/Items/ZoomOut.connect("pressed", self, "_on_ZoomOut_pressed")
	$Header/Items/ZoomReset.connect("pressed", self, "_on_ZoomReset_pressed")
	$Header/Items/Undo.connect("pressed", self, "_on_Undo_pressed")
	$Header/Items/Redo.connect("pressed", self, "_on_Redo_pressed")


func _on_Panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			scroll_container.scroll_horizontal -= event.relative.x
			scroll_container.scroll_vertical -= event.relative.y
			pass

	elif event is InputEventMouseButton:
		if event.pressed:
			var focused: Control = get_focus_owner()
			if focused:
				focused.release_focus()

			if event.button_index == BUTTON_MIDDLE:
				panel.mouse_default_cursor_shape = Control.CURSOR_DRAG

		else:
			panel.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_FileDialog_file_selected(file_path: String) -> void:
	match $FileDialog.get_meta("operation"):
		"save":
			save_graph(file_path)

		"load":
			load_graph(file_path)

		"export":
			# TODO: make export option (graph without editor_data)
			pass


func _on_FileDialog_visibility_changed() -> void:
	$FileDialog.current_dir = $FileDialog.current_dir
	pass


func _on_SaveButton_pressed() -> void:
	popup_save()
	pass


func _on_LoadButton_pressed() -> void:
	popup_load()
	pass


func _on_ExportButton_pressed() -> void:
	popup_export()
	pass


#func _on_DeleteButton_pressed() -> void:
#	var on_focus = get_focus_owner()
#	if not on_focus: return
#
#	if on_focus.get("can_be_deleted"):
#		on_focus.queue_free()


func _on_AddNodeButton_pressed() -> void:
	var position: Vector2 = panel.get_local_mouse_position()
	var new_pge_node = pge_node_packed_scene.instance()

	PGE.undoredo_add_node(new_pge_node, nodes)

	_initialize_node(new_pge_node, position - new_pge_node.header.rect_size / 2.0)
	new_pge_node.grab_focus()
	refresh_panel_size()


func _on_ZoomIn_pressed() -> void:
	if $ScrollContainer.rect_scale.x >= _zoom_max: return

	$ScrollContainer.rect_scale.x += _zoom_step
	$ScrollContainer.rect_scale.y += _zoom_step
	$ScrollContainer.rect_size = _scroll_container_initial_size / $ScrollContainer.rect_scale
	pass


func _on_ZoomOut_pressed() -> void:
	if $ScrollContainer.rect_scale.x <= _zoom_min: return

	$ScrollContainer.rect_scale.x -= _zoom_step
	$ScrollContainer.rect_scale.y -= _zoom_step
	$ScrollContainer.rect_size = _scroll_container_initial_size / $ScrollContainer.rect_scale
	pass


func _on_ZoomReset_pressed() -> void:
	$ScrollContainer.rect_scale = Vector2(1, 1)
	$ScrollContainer.rect_size = _scroll_container_initial_size * $ScrollContainer.rect_scale
	pass


func _on_Undo_pressed() -> void:
	if not PGE.undoredo.is_commiting_action():
		PGE.undoredo.undo()


func _on_Redo_pressed() -> void:
	if not PGE.undoredo.is_commiting_action():
		PGE.undoredo.redo()


func _on_pge_node_tree_exited(pge_node: PanelContainer) -> void:
	refresh_panel_size()


func _on_pge_node_dragged(pge_node) -> void:
	if pge_node.rect_position.x < 0:
		pge_node.rect_position.x = 0

	if pge_node.rect_position.y < 0:
		pge_node.rect_position.y = 0

	# Resize panel only if it would get bigger
	var node_end: Vector2 = pge_node.rect_position + pge_node.rect_size
	var panel_end: Vector2 = panel.rect_size

	if node_end.x > panel_end.x or node_end.y > panel_end.y:
		refresh_panel_size()


func _on_pge_node_drag_ended(pge_node) -> void:
	refresh_panel_size()


# BUTTON_WHEEL events doesn't work with button shortcuts, so zoom shortcut is implemented here
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if Input.is_key_pressed(KEY_CONTROL):
				_on_ZoomIn_pressed()

			elif Input.is_key_pressed(KEY_SHIFT):
				scroll_container.scroll_horizontal -= 3

			else:
				scroll_container.scroll_vertical -= 3

		elif event.button_index == BUTTON_WHEEL_DOWN:
			if Input.is_key_pressed(KEY_CONTROL):
				_on_ZoomOut_pressed()

			elif Input.is_key_pressed(KEY_SHIFT):
				scroll_container.scroll_horizontal += 3

			else:
				scroll_container.scroll_vertical += 3


func clear() -> void:
	graph_name.text = NEW_GRAPH_NAME
	for edge in edges.get_children():
		edge.queue_free()
	for node in nodes.get_children():
		node.queue_free()


func add_node() -> PanelContainer:
	var new_pge_node = pge_node_packed_scene.instance()
	nodes.add_child(new_pge_node, true)
	_initialize_node(new_pge_node)
	return new_pge_node


func _initialize_node(pge_node: PanelContainer, position: = Vector2()) -> void:
	pge_node.connect("tree_exited", self, "_on_pge_node_tree_exited", [pge_node])
	pge_node.connect("drag_started", self, "_on_pge_node_drag_started", [pge_node])
	pge_node.connect("dragged", self, "_on_pge_node_dragged", [pge_node])
	pge_node.connect("drag_ended", self, "_on_pge_node_drag_ended", [pge_node])
	pge_node.slot.edges_parent_path = edges.get_path()

	if position:
		pge_node.move_to(position)


func open_graph(graph: PGEGraph) -> void:
	# TODO: show loading state message while loading
	clear()

	# Wait the nodes actually get cleaned
	while nodes.get_child_count():
		yield(get_tree(), "idle_frame")

	# Parse the data with a DFS
	for node_data in graph.nodes.values():
		_open_graph_from_node_dfs(graph, node_data)

	# Hack: refresh edges after 2 frames
	# After created the actual sizes of the edges from_slot and to_slot take a
	# couple of frames to be set.
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	refresh_edges()


func _open_graph_from_node_dfs(graph: PGEGraph, node_data: Dictionary) -> Node:
	# Get or create node
	var pge_node: Node = get_pge_node(node_data.editor_data.name)
	if not pge_node:
		var node_filename: String = node_data.editor_data.filename

		pge_node = add_node()
		pge_node.set_editor_data(node_data.editor_data)

		# Get or create it's blocks
		for block_data in node_data.blocks:
			var block_filename: String = block_data.editor_data.filename
			var pge_block = pge_node.blocks.get_node_or_null(block_data.editor_data.get("name", "*"))

			if not pge_block:
				pge_block = pge_node.add_block(block_filename)

			pge_block.set_editor_data(block_data.editor_data)
			pge_block.set_data(block_data.get("data", {}))

			for i in range(block_data.connections.size()):
				var connection: String = block_data.connections[i]
				var connected_node_data: Dictionary = graph.nodes[connection]

				var connected_node = _open_graph_from_node_dfs(graph, connected_node_data)
				pge_block.connect_to(i, connected_node)

	return pge_node


func get_pge_node(node_name: String) -> Node:
	return nodes.get_node_or_null(node_name)


func save_graph(file_path: String) -> void:
	graph_name.text = file_path.get_file().trim_suffix(".tres")
	_graph.nodes = serialize()
	ResourceSaver.save(file_path, _graph)


func load_graph(file_path: String) -> void:
	var resource: = load(file_path)
	if not resource:
		$Messages.show_message("Failed on loading resource from path %s." % file_path)
		return

	if not resource is PGEGraph:
		$Messages.show_message("Resourse from path %s is not a valid PGEGraph resource." % file_path)
		return

	graph_name.text = file_path.get_file().trim_suffix(".tres")
	_graph = resource

	open_graph(_graph) # TODO: opening the graph doesn't has to register everything under UndoRedo
	emit_signal("graph_loaded")


func serialize() -> Dictionary:
	var nodes_data: = {}

	for pge_node in nodes.get_children():
		nodes_data[pge_node.name] = pge_node.serialize()

	return nodes_data


func refresh_edges() -> void:
	for edge in edges.get_children():
		edge.refresh()


func popup_save() -> void:
	$FileDialog.mode = FileDialog.MODE_SAVE_FILE
	$FileDialog.window_title = _popup_titles["save"]
	$FileDialog.popup_centered(Vector2())
	$FileDialog.set_meta("operation", "save")


func popup_load() -> void:
	$FileDialog.mode = FileDialog.MODE_OPEN_FILE
	$FileDialog.window_title = _popup_titles["load"]
	$FileDialog.popup_centered(Vector2())
	$FileDialog.set_meta("operation", "load")


func popup_export() -> void:
	$FileDialog.mode = FileDialog.MODE_SAVE_FILE
	$FileDialog.window_title = _popup_titles["export"]
	$FileDialog.popup_centered(Vector2())
	$FileDialog.set_meta("operation", "export")


func refresh_panel_size() -> void:
	var panel_size: = Vector2()
	var window_size: = OS.window_size

	for child in nodes.get_children():
		var child_end: Vector2 = child.rect_position + child.rect_size

		if child_end.x > panel_size.x:
			panel_size.x = child_end.x
			pass
		if child_end.y > panel_size.y:
			panel_size.y = child_end.y
			pass

	if panel_size.x <= window_size.x:
		panel_size.x = window_size.x

	if panel_size.y <= window_size.y:
		panel_size.y = window_size.y - $Header.rect_size.y

	panel.rect_min_size.x = panel_size.x + panel_margin
	panel.rect_size.x = panel.rect_min_size.x

	panel.rect_min_size.y = panel_size.y + panel_margin
	panel.rect_size.y = panel.rect_min_size.y