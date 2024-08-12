extends Node3D

# Preload the block(s)
var block_dirt : PackedScene = preload("res://scenes/minecraft/dirt.tscn")
var block_grass : PackedScene = preload("res://scenes/minecraft/grass.tscn")

# Note: `@onready` variables are set when the scene is loaded.
@onready var ui = $player/camera_mount/Camera3D/ui


## Called when the node enters the scene tree for the first time.
func _ready():
	# Enable UI
	$player.enable_ui = true
	# Show the UI
	ui.visible = true
	# fill <from: x y z> <to: x y z> <tileName: Block>
	fill(Vector3(-10, -2, -10), Vector3(10, -2, 10), block_dirt)
	fill(Vector3(-10, -1, -10), Vector3(10, -1, 10), block_dirt)
	fill(Vector3(-10, 0, -10), Vector3(10, 0, 10), block_grass)


## fill <from: x y z> <to: x y z> <tileName: Block>
func fill(from: Vector3, to: Vector3, block: PackedScene) -> void:
	# Determine the minimum and maximum coordinates for each axis
	var min_x = min(from.x, to.x)
	var max_x = max(from.x, to.x)
	
	var min_y = min(from.y, to.y)
	var max_y = max(from.y, to.y)
	
	var min_z = min(from.z, to.z)
	var max_z = max(from.z, to.z)

	# Loop through each coordinate in the 3D space
	for x in range(int(min_x), int(max_x) + 1):
		for y in range(int(min_y), int(max_y) + 1):
			for z in range(int(min_z), int(max_z) + 1):
				# Instantiate the block scene
				var block_instance = block.instantiate()
				
				# Set the position of the block
				block_instance.transform.origin = Vector3(x, y, z)
				
				# Add the block to the scene
				add_child(block_instance)


## setblock <position: x y z> <tileName: Block>
func setblock(position: Vector3, block: PackedScene) -> StaticBody3D:
	# Instance the preloaded scene
	var block_instance = block.instantiate() as StaticBody3D
	# Set the position of the instance
	block_instance.transform.origin = position
	return block_instance
