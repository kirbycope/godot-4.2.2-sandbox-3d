extends CharacterBody3D

@onready var animation_player = $"visuals/Root Scene/AnimationPlayer"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !animation_player.is_playing():
		animation_player.play("Armature_001|Walk")
