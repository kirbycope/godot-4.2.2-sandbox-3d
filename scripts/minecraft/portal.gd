extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite3D.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	if body is CharacterBody3D:
		# Switch to the specified scene 
		get_tree().change_scene_to_file("res://scenes/minecraft/minecraft.tscn")
		
