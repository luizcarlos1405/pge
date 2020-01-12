extends MenuButton
"""
	Keeps track of wich items can be added to this current GraphNode, count how
	many of each item it has and avoid passing the max_per_node for each item
"""

var _block_count: = {} # Count blocks by it's filenames

onready var pge_node = $"../../.."
onready var popup: = get_popup()


func _ready():
	popup.connect("index_pressed", self, "_on_popup_menu_index_pressed")


func _on_popup_menu_index_pressed(index: int) -> void:
	var pge_block = popup.get_item_metadata(index).instance()

	PGE.undoredo_add_block(pge_block, pge_node.blocks)

	pge_node._initialize_block(pge_block)
	# BUG: if the block is created by loading a graph the counter will not work
	if not _block_count.has(pge_block.filename):
		_block_count[pge_block.filename] = 1
	else:
		_block_count[pge_block.filename] += 1

	if pge_block.max_per_node and _block_count[pge_block.filename] >= pge_block.max_per_node:
		popup.set_item_disabled(index, true)
		pass


func _on_pge_block_tree_exited(pge_block) -> void:
	if pge_block.max_per_node <= 0: return

	for i in popup.get_item_count():
		var packed_scene: PackedScene = popup.get_item_metadata(i)

		if packed_scene == load(pge_block.filename):
			_block_count[pge_block.filename] -= 1
			popup.set_item_disabled(i, false)

			if _block_count[pge_block.filename] <= 0:
				_block_count.erase(pge_block.filename)

			break


func set_block_options(blocks_data: Array) -> void:
	popup.clear()

	for i in range(blocks_data.size()):
		var data = blocks_data[i]
		popup.add_item(data.text)
		popup.set_item_metadata(i, load(data.scene_path))
