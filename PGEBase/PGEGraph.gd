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
					'type': String, # Optional categorization of the block, defaults to 'None'
					'data': Dictionary # data payload returned by get_data method
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


func go_to(node_name: String) -> Dictionary:
	current_node = get_node(node_name)

	return current_node


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