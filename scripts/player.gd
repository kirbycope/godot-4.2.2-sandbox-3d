extends CharacterBody3D

# Note: `@export` variables to make them available in the Godot Inspector.
@export var double_jump_enabled := false
@export var look_sensitivity := 120.0
@export var mouse_sensitivity_horizontal := 0.2
@export var mouse_sensitivity_vertical := 0.2
@export var player_jump_velocity := 4.5
@export var player_crouching_speed := 1.0
@export var player_running_speed := 5.0
@export var player_walking_speed := 3.0

# Note: `@onready` variables are set when the scene is loaded.
@onready var animation_player = $visuals/AuxScene/AnimationPlayer
@onready var debug = $camera_mount/Camera3D/debug
@onready var debug_double_jump = $camera_mount/Camera3D/debug/OptionCheckBox1
@onready var debug_action = $camera_mount/Camera3D/debug/LastActionTextEdit
@onready var debug_animation = $camera_mount/Camera3D/debug/CurrentAnimationTextEdit
@onready var camera = $camera_mount
@onready var visuals = $visuals

var camera_y_rotation := 0.0
var camera_x_rotation := 0.0
var is_crouching := false # Tracks if the player is crouching
var is_double_jumping := false # Tracks if the player is double-jumping
var is_locked := false # Prevents player movement if true
var is_jumping := false # Tracks if the player is jumping
var is_kicking := false # Tracks if the player is kicking
var is_punching := false # Tracks if the player is punching
var is_sprinting := false # Tracks if the player is sprinting
var is_walking := false # Tracks if the player is walking
var game_paused := false # Tracks if the player has paused the game
var player_current_speed := 3.0 # Tracks the player's current speed

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Disable the mouse pointer and capture the motion
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Hide the debug menu
	debug.visible = false

# Called once for every event before _unhandled_input(), allowing you to consume some events.
func _input(event) -> void:
	if !game_paused:
		# Rotate camera based on mouse movement
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x*mouse_sensitivity_horizontal))
			visuals.rotate_y(deg_to_rad(event.relative.x*mouse_sensitivity_horizontal))
			camera.rotate_x(deg_to_rad(-event.relative.y*mouse_sensitivity_vertical))

# Called each physics frame with the time since the last physics frame as argument (delta, in seconds).
func _physics_process(delta) -> void:
	
	# Reset animation lock
	if !animation_player.is_playing():
		animation_player.play("Idle")
		is_kicking = false
		is_locked = false
		is_punching = false
	
	# Handle [crouch] button press
	if Input.is_action_just_pressed("crouch"):
		if animation_player.current_animation != "Standing_To_Crouched":
				animation_player.play("Standing_To_Crouched")
				player_current_speed = player_crouching_speed
				is_crouching = true
	# Handle [crouch] button hold
	elif Input.is_action_pressed("crouch"):
		if animation_player.current_animation != "Standing_To_Crouched":
			if animation_player.current_animation != "Crouching_Idle":
					animation_player.play("Crouching_Idle")
	# Handle [crouch] button release
	elif Input.is_action_just_released("crouch"):
		animation_player.play("Crouched_To_Standing")
		player_current_speed = player_walking_speed
		is_crouching = false
	
	# Handle [kick] button press
	if Input.is_action_just_pressed("kick"):
			if animation_player.current_animation != "Kicking":
				animation_player.play("Kicking")
				is_locked = true
				is_kicking = true
	
	# Handle [punch] button press
	if Input.is_action_just_pressed("punch"):
		if animation_player.current_animation != "Punching":
				animation_player.play("Punching")
				is_locked = true
				is_punching = true
	
	# Handle [sprint] button press
	if Input.is_action_just_pressed("sprint"):
		player_current_speed = player_running_speed
		is_sprinting = true
	# Handle [sprint] button release
	if Input.is_action_just_released("sprint"):
		player_current_speed = player_walking_speed
		is_sprinting = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if !is_locked:
			if is_on_floor():
				if is_sprinting:
					if animation_player.current_animation != "Running_InPlace":
						animation_player.play("Running_InPlace")
				else:
					if animation_player.current_animation != "Walking_InPlace":
						animation_player.play("Walking_InPlace")
			visuals.look_at(position + direction)
		velocity.x = direction.x * player_current_speed
		velocity.z = direction.z * player_current_speed
	else:
		if animation_player.current_animation == "Running_InPlace":
			# Known Issue: Animation moves ahead of player.
			#animation_player.play("Run_To_Stop")
			pass
		elif animation_player.current_animation == "Walking_InPlace":
			animation_player.stop()
		velocity.x = move_toward(velocity.x, 0, player_current_speed)
		velocity.z = move_toward(velocity.z, 0, player_current_speed)
	
	# Handle [jump] button press
	if Input.is_action_just_pressed("jump") and is_on_floor():
		#animation_player.play("Jumping_Up")
		velocity.y = player_jump_velocity
		is_double_jumping = false
		is_jumping = true
	# Handle [jump] button press, again (double-jump
	if Input.is_action_just_pressed("jump") and not is_on_floor():
		if double_jump_enabled:
			if !is_double_jumping:
				#animation_player.play("Jumping_Up")
				velocity.y = player_jump_velocity
				is_double_jumping = true
	if Input.is_action_pressed("jump") and not is_on_floor():
		animation_player.play("Falling_Idle")
	if animation_player.current_animation == "Falling_Idle" and is_on_floor():
		animation_player.stop()
		is_jumping = false
	
	# Move player
	if !is_locked:
		move_and_slide()
	
	# Handle [look_*] using controller
	var look_actions = ["look_down", "look_up", "look_left", "look_right"]
	for action in look_actions:
		if Input.is_action_pressed(action):
			var look_up = Input.get_action_strength("look_up")
			var look_down = Input.get_action_strength("look_down")
			var look_left = Input.get_action_strength("look_left")
			var look_right = Input.get_action_strength("look_right")
			camera_x_rotation += (look_up - look_down) * look_sensitivity * delta
			camera_y_rotation += (look_left - look_right) * look_sensitivity * delta
			camera_x_rotation = clamp(camera_x_rotation, -90, 90)
			rotation_degrees.y = camera_y_rotation
			camera.rotation_degrees.x = camera_x_rotation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Toggle "debug" visibility
	if Input.is_action_just_pressed("debug"):
		debug.visible = !debug.visible
	# Handle [debug] options
	if debug.visible:
		# Toggle double-jump
		double_jump_enabled = debug_double_jump.button_pressed
		# Update "Last action called:"
		var input_map = InputMap.get_actions()
		for action in input_map:
			if Input.is_action_just_pressed(action):
				debug_action.text = action
		# Update "Current animation:"
		debug_animation.text = animation_player.current_animation
	# Toggle "pause" menu
	if Input.is_action_just_pressed("pause"):
		game_paused = !game_paused
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if game_paused else Input.MOUSE_MODE_CAPTURED)
