extends Node3D

# Note: `@onready` variables are set when the scene is loaded.
@onready var loading_scene = preload("res://scenes/loading.tscn")

var loading_scene_instance = null # Container for the loading screen
var player = null # Container for the Player


# Called when the node enters the scene tree for the first time.
func _ready():
	# Load the "loading" scene
	loading_screen_show()
	# Load the "main" scene
	load_scene("res://scenes/main.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


## Hides the "loading..." scene.
func loading_screen_hide() -> void:
	# Check for the "loading..." scene
	if loading_scene_instance != null:
		# Remove the instance from the current scene
		loading_scene_instance.queue_free()
		# Reset the instance container
		loading_scene_instance = null


## Shows the "loading..." scene.
func loading_screen_show() -> void:
	# Instantiate the scene
	loading_scene_instance = loading_scene.instantiate()
	# Add the instance to the current scene
	add_child(loading_scene_instance)


## Loads the given scene into _this_ one.
func load_scene(path:String) -> void:
	# Load the main scene
	var scene = load(path)
	# Instantiate the scene
	var instance = scene.instantiate()
	# Add the instance to the current scene
	add_child(instance)
	# Hide the loading screen
	loading_screen_hide()
