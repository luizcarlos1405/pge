extends Line2D
class_name PGEEdge

"""
	Draws a line between two PGESlots. Use `connect_slots` method to directly
	create the connection or `start_connecting` to start dragging to the mouse.
"""

enum SlotSide {LEFT, RIGHT}

const MIN_X_BEZIER_TANGENT: = 30.0

var from_slot setget set_from_slot
var to_slot setget set_to_slot
var from_slot_overwrite

var connecting_slot # While still dragging, has the drag origin
var _curve: = Curve2D.new()


func _ready() -> void:
	default_color = Color(1, 1, 1, 0.5)
	width = 2
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	gradient = Gradient.new()

	gradient.set_color(0, Color(1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1))

	_curve.add_point(Vector2())
	_curve.add_point(Vector2())



func _on_Slot_rect_changed() -> void:
	# Sometimes the rect changes, but the refresh is called before the values
	# actually change. Let's wait a little
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if connecting_slot:
			var tangents: Dictionary

			_curve.set_point_position(0, to_local(connecting_slot.get_global_position()) + connecting_slot.get_size() / 2.0)
			_curve.set_point_position(1, to_local(event.global_position))
			tangents = get_bezier_tangents(_curve.get_point_position(0),
					_curve.get_point_position(1), connecting_slot.tangent_x_direction, 0)

			_curve.set_point_out(0, tangents.from_out)
			_curve.set_point_in(1, tangents.to_in)

			points = _curve.get_baked_points()


#func _draw() -> void:
#	if points.size() >= 4:
#		var point_count: = points.size()
#		var dir: = (points[point_count - 4] - points[point_count - 1]).normalized()
#		var tip: = points[point_count - 4]
#		var base_left: = tip + dir.rotated(PI / 10) * 20
#		var base_right: = tip + dir.rotated(-PI / 10) * 20
#		draw_polygon(PoolVector2Array([tip, base_left, base_right]), [gradient.get_color(1), gradient.get_color(1), gradient.get_color(1)] )
#		draw_line(tip, base_left, gradient.get_color(1), width)
#		draw_line(tip, base_right, gradient.get_color(1), width)
#		draw_line(base_left, base_right, gradient.get_color(1), width)
#	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not (to_slot and from_slot):
			queue_free()


func start_connecting(start_slot) -> void:
	connecting_slot = start_slot
	gradient.set_color(0, connecting_slot.normal_modulate)


func connect_slots(start_slot, end_slot) -> void:
	set_from_slot(start_slot)
	set_to_slot(end_slot)
	connecting_slot = null

	refresh()

# Recalculate the curve points of the connection line
func refresh() -> void:
	var from_slot_direction: = 0
	var to_slot_direction: = 0

	if not from_slot_overwrite:
		if from_slot:
			_curve.set_point_position(0, to_local(from_slot.get_global_position()) + from_slot.get_size() / 2.0)
			from_slot_direction = from_slot.tangent_x_direction
		else:
			_curve.set_point_position(0, get_global_mouse_position())
	else:
		_curve.set_point_position(0, to_local(from_slot_overwrite.get_global_position()) + from_slot_overwrite.get_size() / 2.0)
		from_slot_direction = from_slot_overwrite.tangent_x_direction

	if to_slot:
		_curve.set_point_position(1, to_local(to_slot.get_global_position()) + to_slot.get_size() / 2.0)
		to_slot_direction = to_slot.tangent_x_direction
	else:
		_curve.set_point_position(1, get_global_mouse_position())

	var tangents = get_bezier_tangents(_curve.get_point_position(0),
			_curve.get_point_position(1), from_slot_direction, to_slot_direction)

	_curve.set_point_out(0, tangents.from_out)
	_curve.set_point_in(1, tangents.to_in)

	points = _curve.get_baked_points()

	update()


func set_from_slot(value) -> void:
	from_slot = value

	from_slot.connect("item_rect_changed", self, "_on_Slot_rect_changed")

	gradient.set_color(0, from_slot.normal_modulate)


func set_to_slot(value) -> void:
	to_slot = value

	to_slot.connect("item_rect_changed", self, "_on_Slot_rect_changed")

	gradient.set_color(1, to_slot.normal_modulate)


func get_bezier_tangents(
		from_point: Vector2,
		to_point: Vector2,
		from_slot_direction: int,
		to_slot_direction: int
	) -> Dictionary:

	var x_distance: = to_point.x - from_point.x
	var tangents: = {
		from_in = Vector2(),
		from_out = Vector2(),
		to_in = Vector2(),
		to_out = Vector2(),
	}

	if x_distance >= 0:
		if from_slot_direction == 1:
			tangents.from_out = Vector2(MIN_X_BEZIER_TANGENT, 0)

		elif from_slot_direction == -1:
			tangents.from_out = Vector2(-get_x_bezier_from_distance(x_distance), 0)

		if to_slot_direction == 1:
			tangents.to_in = Vector2(get_x_bezier_from_distance(x_distance), 0)

		elif to_slot_direction == -1:
			tangents.to_in = Vector2(-MIN_X_BEZIER_TANGENT, 0)

	else:
		if from_slot_direction == 1:
			tangents.from_out = Vector2(get_x_bezier_from_distance(x_distance), 0)

		elif from_slot_direction == -1:
			tangents.from_out = Vector2(-MIN_X_BEZIER_TANGENT, 0)

		if to_slot_direction == 1:
			tangents.to_in = Vector2(MIN_X_BEZIER_TANGENT, 0)

		elif to_slot_direction == -1:
			tangents.to_in = Vector2(-get_x_bezier_from_distance(x_distance), 0)

	return tangents


func get_x_bezier_from_distance(x_distance: float) -> float:
	return MIN_X_BEZIER_TANGENT * log(abs(x_distance)) + MIN_X_BEZIER_TANGENT
	pass