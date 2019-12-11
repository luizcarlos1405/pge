tool
extends Button

"""
	It connects via the Godot's drag system. A controller has to be provided
	or it will assume it's controlling itself. Use `set_controller` method or
	provide the controler's NodePath in the variable `controller_path`.

	The edges (Line2D) will be set as child of the node in the path
	`edges_parent_path` or as child of this slot if no path is provided. This is
	usefull to better control the edge draw order.
"""

enum Mode {BOTH, IN, OUT}
enum TangentDirection {LEFT = -1, NONE = 0, RIGHT = 1}

export(Mode) var mode = Mode.BOTH
export(TangentDirection) var tangent_x_direction: = TangentDirection.NONE setget set_tangent_x_direction
export var max_connections := 0
export var color := Color(1,1,1) setget set_color

var controller: Node = self
var edges_parent_path: = NodePath("")
var popup_menu_rect_min_size = Vector2(50, 2)
var radius := 20.0 setget set_radius
var edges := []


func _ready() -> void:
	connect("gui_input", self, "_on_gui_input")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_tree().set_input_as_handled()

		if event.button_index == BUTTON_RIGHT and event.pressed:
			$PopupMenu.clear()

			if not edges.empty():
				$PopupMenu.popup(Rect2(event.global_position, popup_menu_rect_min_size))


func _on_edge_tree_exiting(edge) -> void:
	edges.erase(edge)


func start_connecting() -> PGEEdge:
	if max_connections:
		if edges.size() >= max_connections:
			return null

	var edge = PGEEdge.new()

	get_node(edges_parent_path).add_child(edge, true)

	edge.start_connecting(self)

	return edge


func receive_connection(edge: PGEEdge):
	if edge.connecting_slot.mode == Mode.IN or mode == Mode.OUT:
		edge.connect_slots(self, edge.connecting_slot)
	else:
		edge.connect_slots(edge.connecting_slot, self)

	edge.from_slot.edges.append(edge)
	edge.connect("tree_exiting", edge.from_slot, "_on_edge_tree_exiting", [edge])

	edge.to_slot.edges.append(edge)
	edge.connect("tree_exiting", edge.to_slot, "_on_edge_tree_exiting", [edge])


func connect_to(slot) -> void:
	var edge: PGEEdge = start_connecting()
	if edge:
		slot.receive_connection(edge)

	edge.refresh()


func get_connections() -> Array:
	var connections = []

	for child in get_children():
		if child is PGEEdge:
			connections.append(child.to_slot)

	return connections


func get_drag_data(position: Vector2) -> Object:
	return start_connecting()


func can_drop_data(position: Vector2, edge: PGEEdge) -> bool:
	if edge.connecting_slot == self or not edge:
		return false

	if edge.connecting_slot.mode == Mode.BOTH or mode == Mode.BOTH:
		return true

	if edge.connecting_slot.mode != mode:
		return true

	return false


func drop_data(position: Vector2, edge: PGEEdge) -> void:
	receive_connection(edge)


func set_edges_parent(node: Node) -> void:
	edges_parent_path = get_path_to(node)


func get_edges_parent() -> Node:
	return get_node(edges_parent_path)


func set_tangent_x_direction(value: int) -> void:
	tangent_x_direction = value


func set_color(value: Color) -> void:
	color = value
	self_modulate = color


func set_radius(value: float) -> void:
	radius = value
	rect_min_size = Vector2(radius * 2, radius * 2)
	rect_size = rect_min_size