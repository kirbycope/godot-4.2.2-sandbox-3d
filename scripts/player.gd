extends CharacterBody3D

# Note: `@export` variables are available for editing in the property editor.
@export var controller_look_sensitivity := 120.0 # Sets the controller's look sensitivity
@export var enable_double_jump := false # Tracks if double-jump is enabled
@export var enable_vibration := false # Tracks if controller vibration is enabled
@export var enable_ui := false # Tracks is the UI is enabled
@export var enable_flying := false # Tracks if flying is enabled
@export var force_kicking := 2.0 # Sets the force for the player's kick
@export var force_kicking_sprinting := 3.0 # Sets the force for the player's kick, while sprinting
@export var force_punching := 1.0 # Sets the force for the player's punch
@export var force_punching_sprinting := 1.5 # Sets the force for the player's punch, while sprinting
@export var force_pushing  := 1.0 # Sets the force for the player's push
@export var force_pushing_sprinting  := 2.0 # Sets the force for the player's push, while sprinting
@export var mouse_sensitivity_horizontal := 0.2 # Set's the mouse's horizontal look sensitivity
@export var mouse_sensitivity_vertical := 0.2 # Set's the mouse's vertical look sensitivity
@export var perspective := 0 # Tracks the perspective of the player (0=third, 1=first, 2=second?)
@export var player_crawling_speed := 0.75 # Sets the player's crawling speed
@export var player_current_speed := 3.0 # Tracks the player's current speed
@export var player_jump_velocity := 4.5 # Sets the player's jump velocity
@export var player_fast_flying_speed := 10.0 # Sets the player's fast flying speed
@export var player_flying_speed := 5.0 # Sets the player's fast flying speed
@export var player_sprinting_speed := 5.0 # Sets the player's sprinting speed
@export var player_walking_speed := 2.5 # Sets the player's walking speed

var animations_crouching = [ "Crawling_InPlace", "Crouching_Idle"] # List of "crouching" (and crawling) animations
var animations_jumping = [ "Falling_Idle" ] # List of "jumping" (and falling) animations
var animations_flying = [ "Flying" ] # List of "flying" (and hovering) animations
var camera_y_rotation := 0.0 # Tracks the camera's roration along the veritcal axis, in relation to the player
var camera_x_rotation := 0.0 # Tracks the camera's roration along the horizontal axis, in relation to the player
var is_animation_locked := false # Tracks if an uninteruptable animation is playing
var is_crouching := false # Tracks if the player is crouching
var is_double_jumping := false # Tracks if the player is double-jumping
var is_flying := false # Tracks if the player is flying
var is_jumping := false # Tracks if the player is jumping
var is_kicking_left := false # Tracks if the player is kicking using a left leg
var is_kicking_right := false # Tracks if the player is kicking using a right leg
var is_punching_left := false # Tracks if the player is kicking using a left arm
var is_punching_right := false # Tracks if the player is kicking using a right arm
var is_sprinting := false # Tracks if the player is sprinting
var is_walking := false # Tracks if the player is walking
var game_paused := false # Tracks if the player has paused the game
var timer_jump := 0.0 # Timer for double-jump to stop flying

# Note: `@onready` variables are set when the scene is loaded.
@onready var animation_player = $visuals/AuxScene/AnimationPlayer
@onready var camera = $camera_mount
@onready var camera_raycast = $camera_mount/RayCast3D
@onready var chat_input = $camera_mount/Camera3D/ui/chat/input
@onready var debug_ui = $camera_mount/Camera3D/debug
@onready var visuals = $visuals

## The gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Disable the mouse pointer and capture the motion
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# DEBUGGING STUFF
	$camera_mount/Camera3D/debug.visible = false
	$camera_mount/Camera3D/ui.visible = false


## Called once for every event before _unhandled_input(), allowing you to consume some events.
## Use _input(event) if you only need to respond to discrete input events, such as detecting a single press or release of a key or button.
func _input(event) -> void:
	
	# [debug] button _pressed_
	if event.is_action_pressed("debug"):
		# Toggle "debug" visibility
		debug_ui.visible = !debug_ui.visible
	
	# If the game is not paused...
	if !game_paused:
		
		# Check for mouse motion
		if event is InputEventMouseMotion:
			# Rotate camera based on mouse movement
			camera_rotate_by_mouse(event)
		
		# [chat] button _pressed_
		if event.is_action_pressed("chat"):
			# Check if the UI is enabled
			if enable_ui:
				# Check if the chat input is already visible
				if chat_input.visible:
					# Release focus on chat input
					chat_input.release_focus()
					# Get the chat input context
					var input = chat_input.text
				# The chat input not yet displayed
				else:
					# Set focus on the chat input
					chat_input.grab_focus()
					# Set the text content
					chat_input.text = ""
				# Toggle chat input visibility
				chat_input.visible = !chat_input.visible
	
		# [command] button _pressed_
		if event.is_action_pressed("command"):
			# Check if the UI is enabled
			if enable_ui:
				# Check if the chat input is not already visible
				if !chat_input.visible:
					# Toggle chat input visibility
					chat_input.visible = !chat_input.visible
					# Check if toggled on
					if chat_input.visible:
						# Set focus on the chat input
						chat_input.grab_focus()
		
		# [crouch] button _pressed_ (and the animation player is not locked)
		if event.is_action_pressed("crouch") and !is_animation_locked:
			# Check if player is flying
			if is_flying:
				# Pitch the player slightly downward
				visuals.rotation.x = deg_to_rad(-6)
			# The player is not flying
			else:
				# Flag the player as "crouching"
				is_crouching = true
		
		# [crouch] button _released_
		if event.is_action_released("crouch"):
			# Check if player is flying
			if is_flying:
				# Reset player pitch
				visuals.rotation.x = 0
			# The player is not flying
			else:
				# Flag player as no longer "crouching"
				is_crouching = false
		
		# [kick-left] button _pressed_ (while grounded and the animation player is not locked)
		if event.is_action_pressed("left_kick") and is_on_floor() and !is_animation_locked:
			# Flag the animation player as locked
			is_animation_locked = true
			# Flag the player as "kicking with their left leg"
			is_kicking_left = true
			# Check if the animation player is not already playing the appropriate animation
			if animation_player.current_animation != "Kicking_Left":
				# Play the left "kicking" animation
				animation_player.play("Kicking_Left")
			# Check the kick hits something
			check_kick_collision()
		
		# [kick-right] button _pressed_ (while grounded and the animation player is not locked)
		if event.is_action_pressed("right_kick") and is_on_floor() and !is_animation_locked:
			# Flag the animation player as locked
			is_animation_locked = true
			# Flag the player as "kicking with their right leg"
			is_kicking_right = true
			# Check if the animation player is not already playing the appropriate animation
			if animation_player.current_animation != "Kicking_Right":
				# Play the right "kicking" animation
				animation_player.play("Kicking_Right")
			# Check the kick hits something
			check_kick_collision()
		
		# [punch-left] button _pressed_ (while grounded and the animation player is not locked)
		if event.is_action_pressed("left_punch") and is_on_floor() and !is_animation_locked:
			# Flag the animation player as locked
			is_animation_locked = true
			# Flag the player as "punching with their left arm"
			is_punching_left = true
			# Check if the player is crouching
			if is_crouching:
				# Check if the animation player is not already playing the appropriate animation
				if animation_player.current_animation != "Punching_Low_Left":
					# Play the left, low "punching" animation
					animation_player.play("Punching_Low_Left")
			# The player should be standing
			else:
				# Check if the animation player is not already playing the appropriate animation
				if animation_player.current_animation != "Punching_Left":
					# Play the left "punching" animation
					animation_player.play("Punching_Left")
			# Check the punch hits something
			check_punch_collision()
		
		# [punch-right] button _pressed_ (while grounded and the animation player is not locked)
		if event.is_action_pressed("right_punch") and is_on_floor() and !is_animation_locked:
			# Flag the animation player as locked
			is_animation_locked = true
			# Flag the player as "punching with their right arm"
			is_punching_right = true
			# Check if the player is crouching
			if is_crouching:
				# Check if the animation player is not already playing the appropriate animation
				if animation_player.current_animation != "Punching_Low_Right":
					# Play the right, low "punching" animation
					animation_player.play("Punching_Low_Right")
			# The player should be standing
			else:
				# Check if the animation player is not already playing the appropriate animation
				if animation_player.current_animation != "Punching_Right":
					# Play the right "punching" animation
					animation_player.play("Punching_Right")
			# Check the punch hits something
			check_punch_collision()
		
		# [perspective] button _pressed_
		if event.is_action_pressed("perspective"):
			# Check if in first-person
			if perspective == 0:
				# Flag the player as in "third" person
				perspective = 1
				# Set camera mount's position
				camera.position = Vector3(0, 1.5, 0)
				# Set camera's position
				camera.get_node("Camera3D").position = Vector3(0, 0.6, 2.5)
			elif perspective == 1:
				# Flag the player as in "first" person
				perspective = 0
				# Set camera mount's position
				camera.position = Vector3(0, 1.7, 0)
				# Set camera's position
				camera.get_node("Camera3D").position = Vector3(0, 0.0, 0.0)
		
		# [sprint] button _pressed_
		if event.is_action_pressed("sprint"):
			# Flag the player as "sprinting"
			is_sprinting = true
		
		# [sprint] button _released_
		if event.is_action_released("sprint"):
			# Flag the player as no longer "sprinting"
			is_sprinting = false

		# [ui] button _pressed_
		if event.is_action_released("ui"):
			print("[ui] button _pressed_")


## Called each physics frame with the time since the last physics frame as argument (delta, in seconds).
## Use _physics_process(delta) if the input needs to be checked continuously in sync with the physics engine, like for smooth movement or jump control.
func _physics_process(delta) -> void:
	
	# Set the player's movement speed
	set_player_speed()
	
	# Check if no animation is playing
	if !animation_player.is_playing():
		# Play the idle "Standing" animation
		animation_player.play("Idle")
		# Flag the animation player no longer locked
		is_animation_locked = false
		is_kicking_left = false
		is_kicking_right = false
		is_punching_left = false
		is_punching_right = false
	
	# Set the player's idle animation, as needed
	set_player_idle_animation()
	
	# If the game is not paused...
	if !game_paused:
		
		# [jump] button _pressed_
		if Input.is_action_pressed("jump"):
			# Check if the player is flying
			if is_flying:
				# Increase the player's vertical position
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
				if enable_double_jump and !is_double_jumping:
					# Set the player's vertical velocity
					velocity.y = player_jump_velocity
					# Set the "double jumping" flag
					is_double_jumping = true
				# Check if flying is enabled and the player is not already flying
				if enable_flying and !is_flying:
					# Start flying
					flying_start()
				# If already flying, angle the player
				elif enable_flying and is_flying:
					# Pitch the player slightly downward
					visuals.rotation.x = deg_to_rad(6)
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
					# Play the idle "Flying" animation
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
					visuals.rotation.x = 0.0
			# The player must be "falling"
			else:
				# Check if the current animation is not the falling one
				if animation_player.current_animation != "Falling_Idle":
					# Play the idle "falling" animation
					animation_player.play("Falling_Idle")

		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		# Check for directional movement
		if direction:
			# Check if the animation player is unlocked
			if !is_animation_locked:
				# Check if the player is on the ground
				if is_on_floor():
					# Check if the player is crouching
					if is_crouching:
						# Play the crouching "move" animation
						if animation_player.current_animation != "Crawling_InPlace":
							animation_player.play("Crawling_InPlace")
					# Check if the player is sprinting
					elif is_sprinting:
						# Play the sprinting "move" animation
						if animation_player.current_animation != "Running_InPlace":
							animation_player.play("Running_InPlace")
					# The player must be walking
					else:
						# Play the walking "move" animation
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
			# Stop any/all "move" animations
			var animations = [ "Crawling_InPlace" , "Running_InPlace", "Walking_InPlace" ]
			for animation in animations:
				if animation_player.current_animation == animation:
					animation_player.stop()
			# Update horizontal veolicty
			velocity.x = move_toward(velocity.x, 0, player_current_speed)
			# Update vertical veolocity
			velocity.z = move_toward(velocity.z, 0, player_current_speed)
		
		# Check if the animation player is unlocked
		if !is_animation_locked:
			# Move player, checking for collision
			if move_and_slide():
				# Check each collision for RigidBody3D
				check_collision_rigidbody3d(delta)
		
		# Handle [look_*] using controller
		var look_actions = ["look_down", "look_up", "look_left", "look_right"]
		for action in look_actions:
			if Input.is_action_pressed(action):
				camera_rotate_by_controller(delta)


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	# Handle [debug] options
	if debug_ui.visible:
		# Minecraft
		$camera_mount/Camera3D/debug/app_version.text = ProjectSettings.get("application/config/name")
		$camera_mount/Camera3D/debug/engine_version.text = debug_get_godot_version()
		$camera_mount/Camera3D/debug/frame.text = debug_get_frame()
		$camera_mount/Camera3D/debug/memory.text = debug_get_memeory()
		$camera_mount/Camera3D/debug/coordinates.text = debug_get_coordinates()
		$camera_mount/Camera3D/debug/facing.text = debug_get_facing()
		## Panel 1
		# Toggle double-jump
		enable_double_jump = $camera_mount/Camera3D/debug/Panel/OptionCheckBox1.button_pressed
		# Toggle flying
		enable_flying = $camera_mount/Camera3D/debug/Panel/OptionCheckBox2.button_pressed
		# Toggle vibration
		enable_vibration = $camera_mount/Camera3D/debug/Panel/OptionCheckBox3.button_pressed
		# Update "Last action called:"
		var input_map = InputMap.get_actions()
		for action in input_map:
			if Input.is_action_just_pressed(action):
				$camera_mount/Camera3D/debug/Panel/LastActionTextEdit.text = action
		# Update "Current animation:"
		$camera_mount/Camera3D/debug/Panel/CurrentAnimationTextEdit.text = animation_player.current_animation
		## Panel 2
		$camera_mount/Camera3D/debug/Panel2/CheckBox1.button_pressed = enable_double_jump
		$camera_mount/Camera3D/debug/Panel2/CheckBox2.button_pressed = enable_flying
		$camera_mount/Camera3D/debug/Panel2/CheckBox3.button_pressed = enable_vibration
		$camera_mount/Camera3D/debug/Panel2/CheckBox4.button_pressed = is_animation_locked
		$camera_mount/Camera3D/debug/Panel2/CheckBox5.button_pressed = is_crouching
		$camera_mount/Camera3D/debug/Panel2/CheckBox6.button_pressed = is_double_jumping
		$camera_mount/Camera3D/debug/Panel2/CheckBox7.button_pressed = is_flying
		$camera_mount/Camera3D/debug/Panel2/CheckBox8.button_pressed = is_jumping
		$camera_mount/Camera3D/debug/Panel2/CheckBox9.button_pressed = is_kicking_left
		$camera_mount/Camera3D/debug/Panel2/CheckBox10.button_pressed = is_kicking_right
		$camera_mount/Camera3D/debug/Panel2/CheckBox11.button_pressed = is_punching_left
		$camera_mount/Camera3D/debug/Panel2/CheckBox12.button_pressed = is_punching_right
		$camera_mount/Camera3D/debug/Panel2/CheckBox13.button_pressed = is_sprinting
		$camera_mount/Camera3D/debug/Panel2/CheckBox14.button_pressed = is_walking
	
	# Check if the [pause] action was just pressed
	if Input.is_action_just_pressed("pause"):
		# Toggle game paused
		game_paused = !game_paused
		# Toggle mouse capture
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if game_paused else Input.MOUSE_MODE_CAPTURED)


# Check if the player (CharacterBody3D) is colliding with a RigidBody3D and apply physics.
func check_collision_rigidbody3d(delta):
	for i in get_slide_collision_count():
		# Get the collision at index `i`
		var collision = get_slide_collision(i)
		# Get the position of the current collision
		var collision_position = collision.get_position()
		# Get the object being collieded with
		var collider = collision.get_collider()
		# Check collider is a physics object
		if collider is RigidBody3D:
			# Enable physics
			collider.freeze = false
			# Define the force to apply to the collided object
			var force = force_pushing if is_sprinting else force_pushing
			# Define the impulse to apply
			var impulse = collision_position - collider.global_position
			# Apply the force to the object
			collider.apply_central_impulse(-impulse * force)


## Check if the kick hits anything.
func check_kick_collision():
	# Get the RayCast3D
	var raycast = $visuals/RayCast3D_InFrontPlayer_Low
	# Check if the RayCast3D is collining with something
	if raycast.is_colliding():
		# Get the object the RayCast is colliding with
		var collider = raycast.get_collider()
		# Get the position of the current collision
		var collision_position = raycast.get_collision_point()
		# Delay execution
		await get_tree().create_timer(0.5).timeout
		# Flag the animation player no longer locked
		is_animation_locked = false
		# Reset action flag(s)
		is_kicking_left = false
		is_kicking_right = false
		# Apply force to RigidBody3D objects
		if collider is RigidBody3D:
			# Define the force to apply to the collided object
			var force = force_kicking_sprinting if is_sprinting else force_kicking
			# Define the impulse to apply
			var impulse = collision_position - collider.global_position
			# Apply the force to the object
			collider.apply_central_impulse(-impulse * force)
		# Call character functions
		if collider is CharacterBody3D:
			# Check side
			if is_kicking_left:
				# Play the appropriate hit animation
				if collider.has_method("animate_hit_low_left"):
					collider.call("animate_hit_low_left")
			else:
				# Play the appropriate hit animation
				if collider.has_method("animate_hit_low_right"):
					collider.call("animate_hit_low_right")
		# Controller vibration
		if enable_vibration:
			Input.start_joy_vibration(0, 0.0 , 1.0, 0.1)


## Checks if the thrown punch hits anything.
func check_punch_collision():
	# Get the RayCast3D
	var raycast = $visuals/RayCast3D_InFrontPlayer_Middle
	# Check if the RayCast3D is collining with something
	if raycast.is_colliding():
		# Get the object the RayCast is colliding with
		var collider = raycast.get_collider()
		# Get the position of the current collision
		var collision_position = raycast.get_collision_point()
		# Delay execution
		await get_tree().create_timer(0.3).timeout
		# Flag the animation player no longer locked
		is_animation_locked = false
		# Reset action flag(s)
		is_punching_left = false
		is_punching_right = false
		# Apply force to RigidBody3D objects
		if collider is RigidBody3D:
			# Define the force to apply to the collided force_punching
			var force = force_punching_sprinting if is_sprinting else force_punching
			# Define the impulse to apply
			var impulse = collision_position - collider.global_position
			# Apply the force to the object
			collider.apply_central_impulse(-impulse * force)
		# Call character functions
		if collider is CharacterBody3D:
			# Check side
			if is_punching_left:
				# Play the appropriate hit animation
				if collider.has_method("animate_hit_high_left"):
					collider.call("animate_hit_high_left")
			else:
				# Play the appropriate hit animation
				if collider.has_method("animate_hit_high_right"):
					collider.call("animate_hit_high_right")
		# Controller vibration
		if enable_vibration:
			Input.start_joy_vibration(0, 1.0 , 0.0, 0.1)


## Rotate camera using the mouse motion.
func camera_rotate_by_mouse(event: InputEvent):
	# Update the player (visuals+camera) opposite the horizontal mouse motion
	rotate_y(deg_to_rad(-event.relative.x*mouse_sensitivity_horizontal))
	# Rotate the visuals opposite the camera direction
	visuals.rotate_y(deg_to_rad(event.relative.x*mouse_sensitivity_horizontal))
	# Rotate the camera based on mouse motion (up/forward and down/backward)
	camera.rotate_x(deg_to_rad(-event.relative.y*mouse_sensitivity_vertical))


## Rotate camera using the right-analog stick.
func camera_rotate_by_controller(delta: float):
	# Get the intensity of each action 
	var look_up = Input.get_action_strength("look_up")
	var look_down = Input.get_action_strength("look_down")
	var look_left = Input.get_action_strength("look_left")
	var look_right = Input.get_action_strength("look_right")
	# Determine the vertical rotation
	camera_x_rotation += (look_up - look_down) * controller_look_sensitivity * delta
	# Limit how far up/down the camera can rotate
	camera_x_rotation = clamp(camera_x_rotation, -90, 90)
	# Rotate camera up/forward and down/backward
	camera.rotation_degrees.x = camera_x_rotation
	# Determine the horizontal rotation
	camera_y_rotation += (look_right - look_left) * controller_look_sensitivity * delta
	# Rotate the visuals opposite the camera direction
	visuals.rotation_degrees.y += (look_right - look_left) * controller_look_sensitivity * delta
	# Rotate camera left and right
	rotation_degrees.y = -camera_y_rotation


## Gets the player coodinates.
func debug_get_coordinates() -> String:
	var coordinates = "XYZ: %.1f / %.1f / %.1f" % [position.x, position.y, position.z]
	return coordinates


## Get the direction the camera (not the player) is facing.
func debug_get_facing() -> String:
	# Get the player's direction vector
	var direction = Vector2(cos(rotation.y), sin(rotation.y)).normalized()
	# Determine the cardinal direction
	var angle = direction.angle()
	# Convert the angle to degrees for easier comparison
	var angle_degrees = rad_to_deg(angle)
	var cardinal_direction = ""
	if angle_degrees >= -45 and angle_degrees < 45:
		cardinal_direction = "North"
	elif angle_degrees >= 45 and angle_degrees < 135:
		cardinal_direction = "West"
	elif angle_degrees >= 135 or angle_degrees < -135:
		cardinal_direction = "South"
	else:
		cardinal_direction = "East"
	return "Facing: " + cardinal_direction


## Gets the fps, max fps, and vsync status.
func debug_get_frame() -> String:
	var fps = Engine.get_frames_per_second()
	var target_fps = Engine.max_fps
	var vsync = "vsync" if ProjectSettings.get("display/window/vsync/vsync_mode") else ""
	var frame = "%s fps T: %s %s" % [fps, target_fps, vsync]
	return frame


## Gets the Godot version.
func debug_get_godot_version() -> String:
	var godot_version = Engine.get_version_info()
	var version_string = "Godot: %d.%d.%d" % [godot_version["major"], godot_version["minor"], godot_version["patch"]]
	return version_string


## Gets the memory used and allocated.
func debug_get_memeory() -> String:
		var used_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
		var max_memory = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
		var used_memory_mb = used_memory / 1024 / 1024
		var max_memory_mb = max_memory / 1024 / 1024
		var memory = "Mem: %d/%d MB" % [used_memory_mb, max_memory_mb]
		return memory


## Start the player flying
func flying_start():
	gravity = 0.0
	motion_mode = MOTION_MODE_FLOATING
	position.y += 0.1
	velocity.y = 0.0
	is_flying = true


## Stop the player flying
func flying_stop():
	gravity = 9.8
	motion_mode = MOTION_MODE_GROUNDED
	velocity.y -= gravity
	visuals.rotation.x = 0
	is_flying = false


## Set's the player's idle animation based on status.
func set_player_idle_animation():

	# Check if the player is "crouching"
	if is_crouching:
		# Check if the current animation is not a crouching one
		if animation_player.current_animation not in animations_crouching:
			# Play the idle "Crouching" animation
			animation_player.play("Crouching_Idle")
	# The player should not be crouching
	else:
		# Check if the current animation is still a crouching one
		if animation_player.current_animation in animations_crouching:
			# Play the standing "Idle" animation
			animation_player.play("Idle")
	
	# Check if the player is "flying"
	if is_flying:
		# Check if the current animation is not a flying one
		if animation_player.current_animation not in animations_flying:
			# Play the idle "Flying" animation
			animation_player.play("Flying")
	# The player should not be flying
	else:
		# Check if the current animation is still a flying one
		if animation_player.current_animation in animations_flying:
			# Play the standing "Idle" animation
			animation_player.play("Idle")
	
	# Check if the player is "jumping"
	if is_jumping:
		# Check if the current animation is not a jumping one
		if animation_player.current_animation not in animations_jumping:
			# Play the idle "Falling" animation
			animation_player.play("Falling_Idle")
	# The player should be "idle"
	else:
		# Check if the current animation is still a jumping one
		if animation_player.current_animation in animations_jumping:
			# Play the standing "Idle" animation
			animation_player.play("Idle")


## Set's the player's movement speed based on status.
func set_player_speed():
	# Check if the player is crouching
	if is_crouching:
		# Set the player's movement speed to the "crawling" speed
		player_current_speed = player_crawling_speed
	# Check if the player is flying and sprinting
	elif is_flying and is_sprinting:
		# Set the player's movement speed to "fast flying"
		player_current_speed = player_fast_flying_speed
	# Check if the player if flying (but not sprinting)
	elif is_flying:
		# Set the player's movement speed to "flying"
		player_current_speed = player_flying_speed
	# Check if the player is sprinting (but not flying)
	elif is_sprinting:
		player_current_speed = player_sprinting_speed
	# The player should be walking (or standing)
	else:
		# Set the player's movement speed to "walking"
		player_current_speed = player_walking_speed
