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
@export var vibration_enabled := false

# Note: `@onready` variables are set when the scene is loaded.
@onready var animation_player = $visuals/AuxScene/AnimationPlayer
@onready var debug = $camera_mount/Camera3D/debug
@onready var debug_double_jump = $camera_mount/Camera3D/debug/OptionCheckBox1
@onready var debug_flying = $camera_mount/Camera3D/debug/OptionCheckBox2
@onready var debug_vibration = $camera_mount/Camera3D/debug/OptionCheckBox3
@onready var debug_action = $camera_mount/Camera3D/debug/LastActionTextEdit
@onready var debug_animation = $camera_mount/Camera3D/debug/CurrentAnimationTextEdit
@onready var camera = $camera_mount
@onready var visuals = $visuals

var animations_crouching = [ "Crawling_InPlace" , "Crouching_Idle"]
var animations_flying = [ "Flying" ]
var camera_y_rotation := 0.0
var camera_x_rotation := 0.0
var is_animation_locked := false # Tracks if an uninteruptable animation is playing
var is_crouching := false # Tracks if the player is crouching
var is_double_jumping := false # Tracks if the player is double-jumping
var is_flying := false # Tracks if the player is flying
var is_jumping := false # Tracks if the player is jumping
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
	
	# Toggle "debug" visibility
	if event.is_action_pressed("debug"):
		debug.visible = !debug.visible
	
	# If the game is not paused...
	if !game_paused:
		
		# Rotate camera based on mouse movement
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x*mouse_sensitivity_horizontal))
			visuals.rotate_y(deg_to_rad(event.relative.x*mouse_sensitivity_horizontal))
			camera.rotate_x(deg_to_rad(-event.relative.y*mouse_sensitivity_vertical))
		
		# [crouch] button _pressed_ (and the animation player is not locked)
		if event.is_action_pressed("crouch") and !is_animation_locked:
			if is_flying:
				# Pitch the player slightly downward
				$visuals/AuxScene.rotation.x = deg_to_rad(6)
			else:
				is_crouching = true
		
		# [crouch] button _released_
		if event.is_action_released("crouch"):
			if is_flying:
				# Reset player pitch
				$visuals/AuxScene.rotation.x = 0
			else:
				is_crouching = false
		
		# [kick-left] button _pressed_ (while grounded)
		if event.is_action_pressed("left_kick") and is_on_floor():
			is_animation_locked = true
			if animation_player.current_animation != "Kicking_Left":
				animation_player.play("Kicking_Left")
			# Check the kick hits something
			check_kick_collision()
		
		# [kick-right] button _pressed_ (while grounded)
		if event.is_action_pressed("right_kick") and is_on_floor():
			is_animation_locked = true
			if animation_player.current_animation != "Kicking_Right":
				animation_player.play("Kicking_Right")
			# Check the kick hits something
			check_kick_collision()
		
		# [punch-left] button _pressed_ (while grounded)
		if event.is_action_pressed("left_punch") and is_on_floor():
			is_animation_locked = true
			if animation_player.current_animation != "Punching_Left":
				animation_player.play("Punching_Left")
			# Check the punch hits something
			check_punch_collision()
		
		# [punch-right] button _pressed_ (while grounded)
		if event.is_action_pressed("right_punch") and is_on_floor():
			is_animation_locked = true
			if animation_player.current_animation != "Punching_Right":
				animation_player.play("Punching_Right")
			# Check the punch hits something
			check_punch_collision()
		
		# [sprint] button _pressed_
		if event.is_action_pressed("sprint"):
			is_sprinting = true
		
		# [sprint] button release
		if event.is_action_released("sprint"):
			is_sprinting = false

# Called each physics frame with the time since the last physics frame as argument (delta, in seconds).
func _physics_process(delta) -> void:
	
		# Set movement speed according to player's action and location
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
	
	# If no animation is playing, play "Idle"
	if !animation_player.is_playing():
		animation_player.play("Idle")
		is_animation_locked = false
	
	# Check if the player is "crouching"
	if is_crouching:
		# Check if the current animation is not a crouching one
		if animation_player.current_animation not in animations_crouching:
			# Play the crouching "Idle" animation
			animation_player.play("Crouching_Idle")
	else:
		# Check if the current animation is still  a crouching one
		if animation_player.current_animation in animations_crouching:
			# Play the standing "Idle" animation
			animation_player.play("Idle")
	
	# If the game is not paused...
	if !game_paused:
		
		# [jump] button _pressed_
		if Input.is_action_pressed("jump"):
			if is_flying:
				position.y += 0.1
		
		# Check if player is on a floor
		if is_on_floor():
			# Check if the falling "Idle" animation is still playing
			if animation_player.current_animation == "Falling_Idle":
				# Play the standing "Idle" animation
				animation_player.play("Idle")
				# Set jumping flag
				is_jumping = false
			# Check if the [jump] action is currently pressed
			if Input.is_action_just_pressed("jump"):
				# Set the player's vertical velocity
				velocity.y = player_jump_velocity
				# Reset the "double jumping" flag
				is_double_jumping = false
				# Check if the player is "flying"
				if !is_flying:
				# Set jumping flag
					is_jumping = true
		# The player is not on a floor
		else:
			# Check if the [jump] action was just pressed
			if Input.is_action_just_pressed("jump"):
				# Check if "double jump" is enabled and the player is not currently double-jumping
				if double_jump_enabled and !is_double_jumping:
					# Set the player's vertical velocity
					velocity.y = player_jump_velocity
					# Set the "double jumping" flag
					is_double_jumping = true
				# Check if flying is enabled and the player is not already flying
				if flying_enabled and !is_flying:
					# Start flying
					flying_start()
				# If already flying, angle the player
				elif flying_enabled and is_flying:
					# Pitch the player slightly downward
					$visuals/AuxScene.rotation.x = deg_to_rad(-6)
				# Check if flying but the "jump timer" hasn't started
				if is_flying and timer_jump == 0.0:
					# Set the "jump timer" to the current game time
					timer_jump = Time.get_ticks_msec()
				# Check if flying and a timer is already running
				elif is_flying and timer_jump > 0.0:
					# Get the current game time
					var time_now = Time.get_ticks_msec()
					# Check if _this_ button press is within 200 milliseconds
					if time_now - timer_jump < 200:
						# Stop flying
						flying_stop()
					# Either way, reset the timer
					timer_jump = Time.get_ticks_msec()
			# Add the gravity.
			velocity.y -= gravity * delta
			# Check if the player is "flying"
			if is_flying:
				# Check if the current animation is not a flying one
				if animation_player.current_animation not in animations_flying:
					# Play the flying "Idle" animation
					animation_player.play("Flying")
				# Check if the [crouch] action is currently pressed
				if Input.is_action_pressed("crouch"):
					# Move down a bit
					position.y -= 0.1
					# End flying if collision detected (below player)
					if $visuals/RayCast3D_BelowPlayer.is_colliding():
						# Stop flying
						flying_stop()
				# Check if the [jump] action is just released
				if Input.is_action_just_released("jump"):
					# Reset player pitch
					$visuals/AuxScene.rotation.x = 0.0
			# The player must be "falling"
			else:
				# Check if the current animation is not the falling one
				if animation_player.current_animation != "Falling_Idle":
					# Play the falling "Idle" animation
					animation_player.play("Falling_Idle")

		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		# If movement was detected...
		if direction:
			# If player is on the ground...
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
			# Update the camera to look in the direction based on player input
			visuals.look_at(position + direction)
			# Update horizontal veolicty
			velocity.x = direction.x * player_current_speed
			# Update vertical veolocity
			velocity.z = direction.z * player_current_speed
		# If no movement detected...
		else:
			# Stop any/all movement based animations
			var animations = [ "Crawling_InPlace" , "Running_InPlace", "Walking_InPlace" ]
			for animation in animations:
				if animation_player.current_animation == animation:
					animation_player.stop()
			# Update horizontal veolicty
			velocity.x = move_toward(velocity.x, 0, player_current_speed)
			# Update vertical veolocity
			velocity.z = move_toward(velocity.z, 0, player_current_speed)
		
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
		# Toggle vibration
		vibration_enabled = debug_vibration.button_pressed
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

func check_kick_collision():
	# Get the RayCast3D
	var raycast = $visuals/RayCast3D_InFrontPlayer_Low
	# Check if the RayCast3D is collining with something
	if raycast.is_colliding():
		# Get the object the RayCast is colliding with
		var collider = raycast.get_collider()
		# Delay execution
		await get_tree().create_timer(0.5).timeout
		# Unlock the animation player
		is_animation_locked = false
		# Apply force
		if collider is RigidBody3D:
			# Apply some force to the collided object
			collider.apply_impulse(-transform.basis.z * 5.0)
		# Controller vibration
		if vibration_enabled:
			Input.start_joy_vibration(0, 0.0 , 1.0, 0.1)

# Checks if the thrown punch hits anything.
func check_punch_collision():
	# Get the RayCast3D
	var raycast = $visuals/RayCast3D_InFrontPlayer_Middle
	# Check if the RayCast3D is collining with something
	if raycast.is_colliding():
		# Get the object the RayCast is colliding with
		var collider = raycast.get_collider()
		# Delay execution
		await get_tree().create_timer(0.3).timeout
		# Unlock the animation player
		is_animation_locked = false
		# Apply force
		if collider is RigidBody3D:
			# Apply some force to the collided object
			collider.apply_impulse(-transform.basis.z * 5.0)
		# Controller vibration
		if vibration_enabled:
			Input.start_joy_vibration(0, 1.0 , 0.0, 0.1)

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
