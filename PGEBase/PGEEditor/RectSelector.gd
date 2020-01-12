extends Control

export var selection_color = Color(1, 1, 1)

var selection_rect: = Rect2(Vector2(), Vector2())

var _selecting: = false

onready var panel: = get_parent()


func _ready() -> void:
	panel.connect("gui_input", self, "_on_Panel_gui_input")


func _on_Panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _selecting:
			selection_rect.end = event.position
			update()

	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_selecting = true
				selection_rect.position = event.position
				selection_rect.size = Vector2()
			else:
				PGE.select_rect(selection_rect.abs(), selection_rect.size.x < 0)
				_selecting = false
				update()


func _draw() -> void:
	if _selecting:
		draw_rect(selection_rect, selection_color, false)