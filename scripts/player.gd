extends CharacterBody3D

# Note: `@export` variables to make them available in the Godot Inspector.
@export var double_jump_enabled := false
@export var flying_enabled := false
@export var look_sensitivity := 120.0
@export var mouse_sensitivity_horizontal := 0.2
@export var mouse_sensitivity_vertical := 0.2
@export var player_jump_velocity := 4.5
@export var player_crawling_speed := 0.75
@export var player_fast_flying_speed := 10.0
@export var player_flying_speed := 5.0
@export var player_running_speed := 5.0
@export var player_walking_speed := 2.5

# Note: `@onready` variables are set when the scene is loaded.
@onready var animation_player = $visuals/AuxScene/AnimationPlayer
@onready var debug = $camera_mount/Camera3D/debug
@onready var debug_double_jump = $camera_mount/Camera3D/debug/OptionCheckBox1
@onready var debug_flying = $camera_mount/Camera3D/debug/OptionCheckBox2
@onready var debug_action = $camera_mount/Camera3D/debug/LastActionTextEdit
@onready var debug_animation = $camera_mount/Camera3D/debug/CurrentAnimationTextEdit
@onready var camera = $camera_mount
@onready var visuals = $visuals

var camera_y_rotation := 0.0
var camera_x_rotation := 0.0
var is_crouching := false # Tracks if the player is crouching
var is_double_jumping := false # Tracks if the player is double-jumping
var is_flying := false # Tracks if the player is flying
var is_jumping := false # Tracks if the player is jumping
var is_kicking_left := false # Tracks if the player is kicking with their left leg
var is_kicking_right := false # Tracks if the player is kicking with their right leg
var is_punching_left := false # Tracks if the player is punching with their left arm
var is_punching_right := false # Tracks if the player is punching with their right arm
var is_sprinting := false # Tracks if the player is sprinting
var is_walking := false # Tracks if the player is walking
var game_paused := false # Tracks if the player has paused the game
var player_current_speed := 3.0 # Tracks the player's current speed
var timer_jump := 0.0 # Timer for double-jump to stop flying

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

	# If the game is not paused...
	if !game_paused:
		
		# Toggle "debug" visibility
		if event.is_action_pressed("debug"):
			debug.visible = !debug.visible
		
		# Rotate camera based on mouse movement
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x*mouse_sensitivity_horizontal))
			visuals.rotate_y(deg_to_rad(event.relative.x*mouse_sensitivity_horizontal))
			camera.rotate_x(deg_to_rad(-event.relative.y*mouse_sensitivity_vertical))
		
		# [crouch] button _pressed_
		if event.is_action_pressed("crouch"):
			if is_flying:
				$visuals/AuxScene.rotation.x = deg_to_rad(6)
			else:
				is_crouching = true
		
		# [crouch] button _released_
		if event.is_action_released("crouch"):
			if is_flying:
				$visuals/AuxScene.rotation.x = 0
			else:
				is_crouching = false
		
		# [kick-left] button _pressed_ (while grounded)
		if event.is_action_pressed("left_kick") and is_on_floor():
			if animation_player.current_animation != "Kicking_Left":
				animation_player.play("Kicking_Left")
			is_kicking_left = true
		
		# [kick-right] button _pressed_ (while grounded)
		if event.is_action_pressed("right_kick") and is_on_floor():
			if animation_player.current_animation != "Kicking_Right":
				animation_player.play("Kicking_Right")
			is_kicking_right = true
		
		# [punch-left] button _pressed_ (while grounded)
		if event.is_action_pressed("left_punch") and is_on_floor():
			if animation_player.current_animation != "Punching_Left":
				animation_player.play("Punching_Left")
			is_punching_left = true
		
		# [punch-right] button _pressed_ (while grounded)
		if event.is_action_pressed("right_punch") and is_on_floor():
			if animation_player.current_animation != "Punching_Right":
				animation_player.play("Punching_Right")
			is_punching_right = true
		
		# [sprint] button _pressed_
		if event.is_action_pressed("sprint"):
			is_sprinting = true
		
		# [sprint] button release
		if event.is_action_released("sprint"):
			is_sprinting = false

# Called each physics frame with the time since the last physics frame as argument (delta, in seconds).
func _physics_process(delta) -> void:
	
	# If nothing is playing, play "Idle"
	if !animation_player.is_playing():
		animation_player.play("Idle")
		is_kicking_left = false
		is_kicking_right = false
		is_punching_left = false
		is_punching_right = false
	
	# Check if the player is no longer [crouching] but the "Crouching_Idle" animation is still playing
	if !is_crouching and animation_player.current_animation == "Crouching_Idle":
		# Make player stand idle
		animation_player.play("Idle")
	
	# Check if the player should be "Crouching"
	if is_crouching:
		# Check they are already not crawling or crounching
		if animation_player.current_animation != "Crawling_InPlace" and animation_player.current_animation != "Crouching_Idle":
			# Make player crouch idle
			animation_player.play("Crouching_Idle")
	
	# Check if the player should be "Falling"
	if !is_on_floor() and !is_flying and animation_player.current_animation != "Falling_Idle":
		# make the player fall idle
		animation_player.play("Falling_Idle")
	
	# Check if the player should be "Flying"
	if !is_on_floor() and is_flying and animation_player.current_animation != "Flying":
		# Make the player fly
		animation_player.play("Flying")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Set speed according to player's action/position
	if is_crouching:
		player_current_speed = player_crawling_speed
	elif is_flying and is_sprinting:
		player_current_speed = player_fast_flying_speed
	elif is_flying:
		player_current_speed = player_flying_speed
	elif is_sprinting:
		player_current_speed = player_running_speed
	else:
		player_current_speed = player_walking_speed
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_on_floor():
			if is_crouching:
				if animation_player.current_animation != "Crawling_InPlace":
					animation_player.play("Crawling_InPlace")
			elif is_sprinting:
				if animation_player.current_animation != "Running_InPlace":
					animation_player.play("Running_InPlace")
			else:
				if animation_player.current_animation != "Walking_InPlace":
					animation_player.play("Walking_InPlace")
		visuals.look_at(position + direction)
		velocity.x = direction.x * player_current_speed
		velocity.z = direction.z * player_current_speed
	else:
		var animations = [ "Crawling_InPlace" , "Running_InPlace", "Walking_InPlace" ]
		for animation in animations:
			if animation_player.current_animation == animation:
				animation_player.stop()
		velocity.x = move_toward(velocity.x, 0, player_current_speed)
		velocity.z = move_toward(velocity.z, 0, player_current_speed)
	
	# [crouch] button _held_ (while flying)
	if Input.is_action_pressed("crouch") and is_flying:
		# Move down a bit
		position.y -= 0.1
		# End flying if collision detected (below player)
		if $RayCast3D.is_colliding():
			flying_stop()
	
	# [jump] button _pressed_ (while on the ground)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = player_jump_velocity
		is_double_jumping = false
		if !is_flying:
			is_jumping = true
	
	# [jump] button _pressed_
	if Input.is_action_pressed("jump"):
		if is_flying:
			position.y += 0.1
	
	# [jump] button _pressed_, again (while in the air)
	if Input.is_action_just_pressed("jump") and not is_on_floor():
		# Double jump, if enabled and not already double-jumping
		if double_jump_enabled and !is_double_jumping:
			velocity.y = player_jump_velocity
			is_double_jumping = true
		# Flying, if enabled and not already flying
		if flying_enabled and !is_flying:
			flying_start()
		# If already flying, angle the player
		elif flying_enabled and is_flying:
			$visuals/AuxScene.rotation.x = deg_to_rad(-6)
		# Start a timer for the first [jump] button press in a series
		if is_flying and timer_jump == 0.0:
			timer_jump = Time.get_ticks_msec()
		# If the timer is already running...
		elif is_flying and timer_jump > 0.0:
			# Check if _this_ button press is within 200 milliseconds
			var time_now = Time.get_ticks_msec()
			if time_now - timer_jump < 200:
				flying_stop()
			# Either way, reset the timer
			timer_jump = Time.get_ticks_msec()
	
	# [jump] button _released_ (if flying)
	if is_flying and Input.is_action_just_released("jump"):
		$visuals/AuxScene.rotation.x = 0.0
	
	# Play the "falling" animation if the player is jumping (and in the air, not flying)
	if Input.is_action_pressed("jump") and not is_on_floor() and !is_flying:
		if animation_player.current_animation != "Falling_Idle":
			animation_player.play("Falling_Idle")
	
	# Stop "falling" animation if the player has returned to the ground
	if animation_player.current_animation == "Falling_Idle" and is_on_floor():
		animation_player.stop()
		is_jumping = false
	
	# Move player
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
	
	# Handle [debug] options
	if debug.visible:
		# Toggle double-jump
		double_jump_enabled = debug_double_jump.button_pressed
		# Toggle flying
		flying_enabled = debug_flying.button_pressed
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

func flying_start():
	gravity = 0.0
	motion_mode = MOTION_MODE_FLOATING
	position.y += 0.1
	velocity.y = 0.0
	is_flying = true

func flying_stop():
	gravity = 9.8
	motion_mode = MOTION_MODE_GROUNDED
	velocity.y -= gravity
	$visuals/AuxScene.rotation.x = 0
	is_flying = false
