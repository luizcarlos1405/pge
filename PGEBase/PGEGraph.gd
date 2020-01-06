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
					'connections': Array, # If empty, it only carries data
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


func get_node(name: String) -> Dictionary:
	if not nodes.has(name):
		push_error("Node with name %s not found." % name)
		return {}

	return nodes[name]


func get_block(node_name: String, block_index: int) -> Dictionary:
	var block_count: int = nodes[node_name].blocks.size()

	if block_index >= block_count:
		push_error("Trying to get block with index %s from node with %s blocks" % [block_index, block_count])
		return {}

	return nodes[node_name].blocks[block_index]


func remove_block(node_name: String, block_index: int) -> Dictionary:
	var block_count: int = nodes[node_name].blocks.size()

	if block_index >= block_count:
		push_error("Trying to remove block with index %s from node with %s blocks" % [block_index, block_count])
		return {}

	var block: Dictionary = nodes[node_name].blocks[block_index]
	nodes[node_name].blocks.remove(block_index)

	return block


func has_connection(from_node_name: String, to_node_name: String) -> bool:
	if not from_node_name or not to_node_name:
		return false

	var origin_node = get_node(from_node_name)
	if origin_node.empty():
		return false

	for block in origin_node.blocks:
		if block.connections.has(to_node_name):
			return true

	return false


func go_to(node_name: String) -> Dictionary:
	current_node = get_node(node_name)

	return current_node


func next(block_index: int, slot_index: = 0) -> Dictionary:
	if current_node.empty():
		push_error("Current_node is empty. Dname you call start()?")
		return {}

	var block_count: int = current_node.blocks.size()

	if block_count <= block_index:
		push_warning("Tried to call next in block with index %s but current node has %s blocks." % [block_index, block_count])
		return current_node

	var block: Dictionary = current_node.blocks[block_index]
	var slots_count: int = block.connections.size()

	if slots_count <= slot_index:
		push_warning("Tried to access slot index %s on a block with %s slots" % [slot_index, slots_count])
		return current_node

	return go_to(block.connections[slot_index])


func get_blocks_by_type(node: = current_node) -> Dictionary:
	if node.empty():
		push_error("Node empty.")
		return {}

	var out: = {}

	for i in range(node.blocks.size()):
		var block: Dictionary = node.blocks[i].duplicate()
		block.index = i
		var type: String = block.get("type", _default_type)

		if out.has(type):
			out[type].append(block)

		else:
			out[type] = [block]

	return out