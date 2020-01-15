tool
extends TextureButton

"""
	Identifies the connection intent and creates an PGEEdge if succesfully
	connected. PGEEdge extends Line2D and draws the connection properly.

	It uses the Godot's drag system. A PGENode has to be set as a controller.
	If it doesn't have a controller it will not work.

	The edges (Line2D) will be set as child of the node in the path
	`edges_parent_path` or as child of this slot if no path or an invalid path
	is provided. This is usefull to better control the edge draw order.
"""

enum Mode {BOTH, IN, OUT, NONE}
enum TangentDirection {LEFT = -1, NONE = 0, RIGHT = 1}

export(Mode) var mode = Mode.BOTH
export(TangentDirection) var tangent_x_direction: = TangentDirection.NONE setget set_tangent_x_direction
export var max_connections: = 1
export var normal_modulate: = Color(1,1,1)
export var hover_modulate: = Color(1, 1, 1)
export var pressed_modulate: = Color(1, 1, 1)
export var disabled_modulate: = Color(1 ,1, 1)
export var texture_right: Texture
export var texture_left: Texture
export var texture_both: Texture

var controller: Node = null # Aways a PGENode
var edges_parent_path: = NodePath("")
var popup_menu_rect_min_size = Vector2(50, 2)
var radius: = 20.0 setget set_radius
var edges: = []


func _ready() -> void:
	if not disabled:
		self_modulate = normal_modulate
	else:
		self_modulate = disabled_modulate

	if mode == Mode.BOTH:
		texture_normal = texture_both

	connect("gui_input", self, "_on_gui_input")
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_tree().set_input_as_handled()

		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				self_modulate = pressed_modulate
			else:
				if self_modulate == pressed_modulate:
					self_modulate = hover_modulate

		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				$PopupMenu.clear()

				if not edges.empty():
					$PopupMenu.popup(Rect2(event.global_position, popup_menu_rect_min_size))


func _on_mouse_entered() -> void:
	self_modulate = hover_modulate


func _on_mouse_exited() -> void:
	self_modulate = normal_modulate


func start_connecting() -> PGEEdge:
	var parent = get_node_or_null(edges_parent_path)
	var edge: = PGEEdge.new()

	if not parent:
		push_warning("Failed to get node on path %s, adding edge as child of the slot." % edges_parent_path)
		parent = self

	parent.add_child(edge)
	edge.start_connecting(self)

	return edge


func receive_connection(edge: PGEEdge):
	if edge.connecting_slot.mode == Mode.IN or mode == Mode.OUT:
		edge.connect_slots(self, edge.connecting_slot)
	else:
		edge.connect_slots(edge.connecting_slot, self)

	edge.from_slot.edges.append(edge)
	edge.to_slot.edges.append(edge)


# An edge can be pre-created calling start_connecting before connect_to
func connect_to(pge_slot, pre_created_edge = null) -> void:
	var edge: PGEEdge = pre_created_edge
	if not is_instance_valid(edge):
		edge = start_connecting()

	pge_slot.receive_connection(edge)
	edge.refresh()


func disconnect_to(pge_slot) -> void:
	for edge in get_edges_from_self():
		if edge.to_slot == pge_slot:
			edges.erase(edge)
			pge_slot.edges.erase(edge)
			edge.queue_free()


func get_edges_from_self() -> Array:
	var edges_from_self: = []
	for edge in edges:
		if edge.from_slot == self:
			edges_from_self.append(edge)

	return edges_from_self


func get_drag_data(position: Vector2) -> Object:
	if not controller or mode == Mode.NONE:
		return null

	if max_connections:
		if edges.size() >= max_connections:
			return null

	return start_connecting()


func can_drop_data(position: Vector2, edge: PGEEdge) -> bool:
	if edge.connecting_slot == self or not edge:
		return false

	if max_connections and edges.size() >= max_connections:
		return false

	if edge.connecting_slot.mode == Mode.BOTH or mode == Mode.BOTH:
		return true

	if edge.connecting_slot.mode != mode:
		return true

	return false


func drop_data(position: Vector2, edge: PGEEdge) -> void:
	PGE.undoredo_connect_slots(edge.connecting_slot, self, edge)


func refresh_edges() -> void:
	for edge in edges:
		edge.refresh()


func set_edges_parent(node: Node) -> void:
	edges_parent_path = get_path_to(node)


func get_edges_parent() -> Node:
	return get_node(edges_parent_path)


func set_tangent_x_direction(value: int) -> void:
	tangent_x_direction = value
	refresh_edges()


func set_normal_modulate(value: Color) -> void:
	normal_modulate = value


func set_hover_modulate(value: Color) -> void:
	hover_modulate = value


func set_pressed_modulate(value: Color) -> void:
	pressed_modulate = value


func set_radius(value: float) -> void:
	radius = value
	rect_min_size = Vector2(radius * 2, radius * 2)
	rect_size = rect_min_size