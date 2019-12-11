extends Resource
class_name PGEGraph

"""
	This resource represents a graph with some traversing methods. The `nodes` variable
	is a Dictionary and has the form of this example:

	{
		'node_name': {
			'editor_data': Dictionary # position, size and other editor informations
			'blocks': [
				{
					'editor_data': Dictionary # filename, size and other editor informations
					'connects_to': String, # If an empty String, it only carries data
					'type': String, # Optional categorization of the block, defaults to 'none'
					'data': Variant # data payload
				},
				...
			]
		},
		...
	}

	All nodes are containers for blocks. Blocks can represent a connection with
	another node and/or carry data defined by implementing `get_data` and `set_data`
	methods.

	The `nodes` variable is an adjacency Dictionary, so checking if a node exists
	or accessing it's blocks is as simple as calling `nodes.has(<name>)`.

	The methods provided easy the tasks of editing and traversing the graph.

	Use `go_to(<node_name>)` to get a node, than read it's blocks to decide if
	you'll use one of their connections or data. Than use `next(<block_id>)` to
	get the node connected with the block `block_id`
"""

export var nodes: = {}

var current_node: = {}

var _default_type: = "None"


# Building methods
func add_node(name: String, data = null, editor_data: = {}) -> Dictionary:
	if nodes.has(name):
		print_debug("[ERROR]: node with name %s already exists." % name)
		return {}

	var new_node: = {
		editor_data = editor_data,
		data = data,
		blocks = []
	}

	nodes[name] = new_node

	return new_node


func get_node(name: String) -> Dictionary:
	if not nodes.has(name):
		print_debug("[ERROR]: node with name %s not found." % name)
		return {}

	return nodes[name]


func remove_node(name: String) -> Dictionary:
	if not nodes.has(name):
		print_debug("[ERROR]: node with name %s not found." % name)
		return {}

	var node: Dictionary = nodes[name]
	nodes.erase(name)

	# Now check all connections to this node and delete them
	for node_name in nodes:
		var blocks: Array = nodes[node_name].blocks
		for i in range(blocks.size() - 1, -1, -1):
			if blocks[i].connects_to == name:
				blocks.remove(i)

	return node


func add_block(
		to_node: String,
		connects_to: = "",
		data = null,
		editor_data: = {},
		type: = _default_type
	) -> Dictionary:

	if has_connection(to_node, connects_to):
		print_debug("[WARNING]: connection from %s to %s already exists. Block not added." % [to_node, connects_to])
		return {}

	var node: = get_node(to_node)
	if node.empty():
		return {}

	var new_block: = {
		connects_to = connects_to,
		data = data,
		editor_data = editor_data,
		type = type
	}

	if not nodes.has(connects_to):
		print_debug("[WARNING]: node with name %s not found. Connection not added.")
		new_block.connects_to = ""

	node.blocks.append(new_block)

	return new_block


func get_block(node_name: String, block_index: int) -> Dictionary:
	var block_count: int = nodes[node_name].blocks.size()

	if block_index >= block_count:
		print_debug("[ERROR]: trying to get block with index %s from node with %s blocks" % [block_index, block_count])
		return {}

	return nodes[node_name].blocks[block_index]


func remove_block(node_name: String, block_index: int) -> Dictionary:
	var block_count: int = nodes[node_name].blocks.size()

	if block_index >= block_count:
		print_debug("[ERROR]: trying to remove block with index %s from node with %s blocks" % [block_index, block_count])
		return {}

	var block: Dictionary = nodes[node_name].blocks[block_index]
	nodes[node_name].blocks.remove(block_index)

	return block


func remove_connection(origin_node_name: String, target_node_name: String) -> Dictionary:
	var origin_node: = get_node(origin_node_name)
	if origin_node.empty():
		return {}

	for block in origin_node.blocks:
		if block.connects_to == target_node_name:
			origin_node.blocks.erase(block)
			return block

	print_debug("[ERROR]: triyng to delete a block that doesn't exist from %s to %s." % [origin_node_name, target_node_name])

	return {}


# Traversing methods
func has_connection(from_node_name: String, to_node_name: String) -> bool:
	if not from_node_name or not to_node_name:
		return false

	var origin_node = get_node(from_node_name)
	if origin_node.empty():
		return false

	for block in origin_node.blocks:
		if block.connects_to == to_node_name:
			return true

	return false


func go_to(node_name: String) -> Dictionary:
	current_node = get_node(node_name)

	return current_node


func next(block_index: int) -> Dictionary:
	if current_node.empty():
		print_debug("[ERROR]: current_node is empty. Dname you call start()?")
		return {}

	var block_count: int = current_node.blocks.size()

	if block_index >= block_count:
		print_debug("[WARNING]: trying call next in block with index %s but current node has %s blocks." % [block_index, block_count])
		return current_node

	return go_to(current_node.blocks[block_index].connects_to)


func get_blocks_by_type(node: = current_node) -> Dictionary:
	if node.empty():
		print_debug("[ERROR]: node current_node empty.")
		return {}

	var out: = {}

	for i in range(node.blocks.size()):
		var block: Dictionary = node.blocks[i].duplicate()
		block.index = i
		if out.has(block.type):
			out[block.type].append(block)

		else:
			out[block.type] = [block]

	return out


func print_nodes() -> void:
	for name in nodes:
		print(name, ": ")
		for block in nodes[name].blocks:
			if block.connects_to:
				print("|_", block.connects_to)