class_name SaveFile
extends Object


const GROUP_SAVED_NODES := "saved node"
const METHOD_SAVE_NODE := "save_node_to"
const METHOD_LOAD_NODE := "load_node_from"


enum SAVEFILE_ERROR { NONE, MISHAPS, FATAL }


# The save file is a *.gmtpn file. It is binary-encoded (padded to 4 bytes) with the program's saved
# nodes information.
# Each node that can be saved in the save file is part of the GROUP_SAVED_NODES and must implement 
# both methods : 
#    METHOD_SAVE_NODE (prototype : `func METHOD_SAVE_NODE(PackedByteArray) -> SAVEFILE_ERROR` ; 
#    METHOD_LOAD_NODE (prototype : `func METHOD_LOAD_NODE(u32, PackedByteArray) -> SAVEFILE_ERROR`.
#
# The save file begins with a header :
#    4 bytes : version of the program as u32
#    4 bytes : number of save blocks as u32
#
# Then, the save file is a succession of save blocks. A save block has its own header (the 'block 
# header') and some binary content (the 'save data').
#
# A block header follows directly the save file header. It looks like this, with positions offset by
# the block header's positon:
#   4 bytes :                length of the node's name (STR NAME LEN) as u32
#   + (STR NAME LEN) bytes : name of the saved node as String
#   + 4 bytes :              length of the node's data (DATA LENGTH) as u32
#   + (DATA LENGTH) bytes:   node's save data passed to node.METHOD_LOAD_NODE


class SaveHeader:
	var program_version : int
	var nb_blocks : int
	
	func _init() -> void:
		self.program_version = ProgramVersion.PROGRAM_VERSION

class SaveBlock:
	var associated_node : StringName
	var data : PackedByteArray
	
	func _init(node_name : StringName) -> void:
		self.associated_node = node_name
		self.data = []


# save the program's persistent nodes to a file represented by *path*. If the path is invalid, or 
# that the file could not be opened for any reason, the save process is aborted.
static func save_state_to(scene_tree : SceneTree, path : String) -> void:
	var saved_objects : Array[Node] = scene_tree.get_nodes_in_group(GROUP_SAVED_NODES)
	var save_content : Array[SaveBlock] = []
	var save_header : SaveHeader
	var save_file : FileAccess
	
	# file access in writing mode
	save_file = FileAccess.open(path, FileAccess.WRITE)
	if not save_file:
		print_debug("Something went wrong when trying to save to ", path, " : ", FileAccess.get_open_error())
		return
	
	# creation of the default program's header
	save_header = SaveHeader.new()
	
	# for each detected node, tru to call the save method and store its return value
	for node in saved_objects:
		if node.has_method(METHOD_SAVE_NODE):
			save_content.append(SaveBlock.new(node.name))
			node.call(METHOD_SAVE_NODE, save_content[-1].data)
			save_header.nb_blocks += 1
		else:
			print_debug("Node ", node, " is in group \"", GROUP_SAVED_NODES, "\" but has no method `", METHOD_SAVE_NODE, "`")
	
	# store header
	save_file.store_32(save_header.program_version)
	save_file.store_32(save_header.nb_blocks)
	
	# store each block
	for save_block in save_content:
		# pascal strings are prefixed by their length
		save_file.store_pascal_string(save_block.associated_node)
		save_file.store_32(len(save_block.data))
		save_file.store_buffer(save_block.data)
	
	save_file.close()


# Load the program's persistent nodes stored in a save file.
static func load_state_from(root_node : Node, path : String) -> void:
	var save_block_header : Dictionary = {}
	var save_file : FileAccess
	var save_header : SaveHeader 
	var tmp_node_loaded : Node
	var save_block_data : PackedByteArray
	
	save_file = FileAccess.open(path, FileAccess.READ)
	if not save_file:
		print_debug("Something went wrong when trying to save to ", path, " : ", FileAccess.get_open_error())
		return
	
	save_header = SaveHeader.new()
	save_header.program_version = save_file.get_32()
	save_header.nb_blocks = save_file.get_32()

	while (save_header.nb_blocks > 0):
		save_block_header["name length"] = save_file.get_32()
		save_block_header["name"] = save_file.get_buffer(save_block_header["name length"]).get_string_from_utf8()
		save_block_header["data length"] = save_file.get_32()
		save_block_data = save_file.get_buffer(save_block_header["data length"])
		
		tmp_node_loaded = root_node.get_node(save_block_header["name"])
		if tmp_node_loaded:
			tmp_node_loaded.call(METHOD_LOAD_NODE, save_header.program_version, save_block_data)
		
		save_header.nb_blocks -= 1
	
	save_file.close()
