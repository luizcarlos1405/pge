extends MenuButton
"""
	Keeps track of wich items can be added to this current GraphNode, count how
	many of each item it has and avoid passing the max_per_node for each item
"""

var _block_count: = {} # Count blocks by it's filenames

onready var graph_node = $"../../.."
onready var popup: = get_popup()


func _ready():
	popup.connect("index_pressed", self, "_on_popup_menu_index_pressed")


func _on_popup_menu_index_pressed(index: int) -> void:
	var block = graph_node.add_block(popup.get_item_metadata(index))

	if not _block_count.has(block.filename):
		_block_count[block.filename] = 1
	else:
		_block_count[block.filename] += 1

	if block.max_per_node and _block_count[block.filename] >= block.max_per_node:
		popup.set_item_disabled(index, true)
		pass


func _on_block_tree_exiting(block) -> void:
	if block.max_per_node <= 0: return

	for i in popup.get_item_count():
		var packed_scene: PackedScene = popup.get_item_metadata(i)

		if packed_scene == load(block.filename):
			_block_count[block.filename] -= 1
			popup.set_item_disabled(i, false)

			if _block_count[block.filename] <= 0:
				_block_count.erase(block.filename)

			break


func set_block_options(blocks_data: Array) -> void:
	popup.clear()

	for i in range(blocks_data.size()):
		var data = blocks_data[i]
		popup.add_item(data.text)
		popup.set_item_metadata(i, data.metadata)
