extends MenuButton
"""
	Keeps track of wich items can be added to this current GraphNode, count how
	many of each item it has and avoid passing the max_per_node for each item
"""


var item_count := {}

onready var graph_node = $"../../.."
onready var popup = get_popup()


func _ready():
	connect("about_to_show", self, "_on_about_to_show")
	popup.connect("index_pressed", self, "_on_popup_menu_index_pressed")
	pass


func _on_about_to_show() -> void:
	pass


func _on_popup_menu_index_pressed(id: int) -> void:
	graph_node.add_block(popup.get_item_metadata(id))
