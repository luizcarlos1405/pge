extends PopupMenu

var delete_icon: Texture = preload("../assets/icons/icon_delete.svg")

onready var slot = get_parent()


func _ready():
	connect("about_to_show", self, "_on_about_to_show")
	connect("index_pressed", self, "_on_index_pressed")
	pass


func _on_about_to_show() -> void:
	clear()

	for edge in slot.edges:
		var item_text = make_item_text(edge)
		add_icon_item(delete_icon, item_text)


func _on_index_pressed(index: int) -> void:
	var item_text = get_item_text(index)

	for edge in slot.edges:
		if item_text == make_item_text(edge):
			PGE.undoredo_remove_edge(edge)


func make_item_text(graph_edge) -> String:
	var from: String = graph_edge.from_slot.controller.name
	var to: String = graph_edge.to_slot.controller.name
	return "%s -> %s" % [from, to]