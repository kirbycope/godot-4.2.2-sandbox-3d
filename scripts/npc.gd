extends CharacterBody3D

@onready var animation_player = $visuals/AuxScene/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !animation_player.is_playing():
		animation_player.play("Idle")

func animate_hit_low_left():
	animation_player.play("Reaction_Low_Left")

func animate_hit_low_right():
	animation_player.play("Reaction_Low_Right")

func animate_hit_high_left():
	animation_player.play("Reaction_High_Left")

func animate_hit_high_right():
	animation_player.play("Reaction_High_Right")
