extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DIG_PERIOD = 0.1
const DIG_OFFSET = Vector2(32, 32)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var dig_timer = DIG_PERIOD

func _update_dig(delta):
	dig_timer -= delta
	if dig_timer <= 0:
		dig_timer = DIG_PERIOD
		# Go a raycast diagonally to attempt a dig in front of the character
		var space_state = get_world_2d().direct_space_state
		var raycast_query = PhysicsRayQueryParameters2D.create(global_position, global_position + DIG_OFFSET)
		raycast_query.exclude = [self]
		var raycast_result = space_state.intersect_ray(raycast_query)
		if not raycast_result.is_empty():
			var tilemap_collided = raycast_result.collider as TileMap
			if tilemap_collided != null:
				var dig_global_pos = raycast_result.position
				tilemap_collided.dig(dig_global_pos)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle dig.
	if Input.is_action_pressed("dig"):
		_update_dig(delta)

	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _process(delta):
	if velocity.x != 0:
		$AnimatedSprite2D.set_flip_h(velocity.x < 0)
