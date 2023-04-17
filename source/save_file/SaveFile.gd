class_name SaveFile
extends Object

## This class is made to save and load nodes in a tree.
##
## Loaded and saved nodes are stored in a binary array.
## [br]
## The save file is a *.gmtpn file. It is binary-encoded (padded to 4 bytes) with the program's saved
## nodes information.[br]
## Each node that can be saved in the save file is part of the GROUP_SAVED_NODES and must implement 
## both methods : 
## [br]   METHOD_SAVE_NODE (prototype : `func METHOD_SAVE_NODE(PackedByteArray) -> SAVEFILE_ERROR` ; 
## [br]   METHOD_LOAD_NODE (prototype : `func METHOD_LOAD_NODE(u32, PackedByteArray) -> SAVEFILE_ERROR`.
## [br]
## The save file begins with a header :
## [br]   4 bytes : version of the program as u32
## [br]   + 4 bytes : number of save blocks as u32
## [br]
## [br]Then, the save file is a succession of save blocks. A save block has its own header (the 'block 
## header') and some binary content (the 'save data').
## [br]
## [br]A block header follows directly the save file header. It looks like this, with positions offset by
## the block header's positon:
## [br]  4 bytes :                length of the node's name (STR NAME LEN) as u32
## [br]  + (STR NAME LEN) bytes : name of the saved node as String
## [br]  + 4 bytes :              length of the node's data (DATA LENGTH) as u32
## [br]  + (DATA LENGTH) bytes:   node's save data passed to node.METHOD_LOAD_NODE

## Group name containing the nodes to be saved.
const GROUP_SAVED_NODES := "saved node"
## Method name to save a node.
const METHOD_SAVE_NODE := "save_node_to"
## Method name to load a node.
const METHOD_LOAD_NODE := "load_node_from"

## Kind of behaviors the SaveFile class can do when an error occurs.
enum SAVEFILE_ERROR { NONE, MISHAPS, FATAL }


# save file's header non-representative data
class SaveHeader:
	var program_version : int
	var nb_blocks : int
	
	func _init() -> void:
		self.program_version = ProgramVersion.PROGRAM_VERSION
	
	func bin_serialize(save_file : FileAccess) -> void:
		save_file.store_32(self.program_version)
		save_file.store_32(self.nb_blocks)
	
	func bin_deserialize(save_file : FileAccess) -> void:
		self.program_version = save_file.get_32()
		self.nb_blocks = save_file.get_32()


# save block header non-representative data
class SaveBlock:
	var associated_node : StringName
	var data : PackedByteArray
	
	func _init(node_name : StringName) -> void:
		self.associated_node = node_name
		self.data = []
	
	func bin_serialize(save_file : FileAccess) -> void:
		# pascal strings are prefixed by their length
		save_file.store_pascal_string(self.associated_node)
		save_file.store_32(len(self.data))
		save_file.store_buffer(self.data)
	
	func bin_deserialize(save_file : FileAccess) -> void:
		var save_block_header : Dictionary = {}
		
		save_block_header["name length"] = save_file.get_32()
		self.associated_node = save_file.get_buffer(save_block_header["name length"]).get_string_from_utf8()
		save_block_header["data length"] = save_file.get_32()
		self.data = save_file.get_buffer(save_block_header["data length"])
		


## Saves the program's persistent nodes to a file represented by *path*. If the path is invalid, or 
## that the file could not be opened for any reason, the save process is aborted.
static func save_state_to(scene_tree : SceneTree, path : String) -> void:
	var save_content : Array[SaveBlock] = []
	var save_header : SaveHeader
	var save_file : FileAccess
	
	# file access in writing mode
	save_file = FileAccess.open(path, FileAccess.WRITE)
	if not save_file:
		print_debug("Something went wrong when trying to save to ", path, " : ", FileAccess.get_open_error())
		return
	
	save_content = _get_saved_objects_from_tree(scene_tree)
	
	if len(save_content) == 0:
		save_file.close()
		return
	
	# creation of the default program's header
	save_header = SaveHeader.new()
	save_header.nb_blocks = len(save_content)
	
	# store header
	save_header.bin_serialize(save_file)
	
	# store each block
	for save_block in save_content:
		# pascal strings are prefixed by their length
		save_block.bin_serialize(save_file)
	
	save_file.close()


## Loads the program's persistent nodes stored in a save file.
static func load_state_from(root_node : Node, path : String) -> void:
	var save_file : FileAccess
	var save_header : SaveHeader = SaveHeader.new()
	var tmp_node_loaded : Node
	var save_block : SaveBlock = SaveBlock.new("")
	
	save_file = FileAccess.open(path, FileAccess.READ)
	if not save_file:
		print_debug("Something went wrong when trying to save to ", path, " : ", FileAccess.get_open_error())
		return
	
	save_header.bin_deserialize(save_file)

	while (save_header.nb_blocks > 0):
		save_block.bin_deserialize(save_file)
		
		tmp_node_loaded = root_node.get_node(save_block.associated_node as String)
		if tmp_node_loaded:
			tmp_node_loaded.call(METHOD_LOAD_NODE, save_header.program_version, save_block.data)
		
		save_header.nb_blocks -= 1
	
	save_file.close()


# return an array of save data from objects wanting to save in a scene tree
static func _get_saved_objects_from_tree(scene_tree : SceneTree) -> Array[SaveBlock]:
	var saved_objects : Array[Node] = scene_tree.get_nodes_in_group(GROUP_SAVED_NODES)
	var save_content : Array[SaveBlock] = []
	var operation_code : SAVEFILE_ERROR	
	
	for node in saved_objects:
		if not node.has_method(METHOD_SAVE_NODE):
			print_debug("Node ", node, " is in group \"", GROUP_SAVED_NODES, "\" but has no method `", METHOD_SAVE_NODE, "`")
			continue
		
		save_content.append(SaveBlock.new(node.name))
		operation_code = node.call(METHOD_SAVE_NODE, save_content[-1].data)
		
		match operation_code:
			SAVEFILE_ERROR.MISHAPS:
				print_debug("Node ", node, " reported an error when saving, continuing anyway")
			SAVEFILE_ERROR.FATAL:
				print_debug("Node ", node, " reported a fatal error when saving, aborting")
				return []
	
	return save_content

