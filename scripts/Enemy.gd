extends CharacterBody2D

const MAX_HP = 10
const INITIAL_HP = MAX_HP
const SPEED = 100.0
const FALL_CHECK_OFFSET = Vector2(32, 32)

@export var hitpoints = INITIAL_HP

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var move_direction = 1

func _fall_test(_delta):
	# Shape cast with our collider to test whether we're about to fall
	var space_state = get_world_2d().direct_space_state
	var shapecast_query_params = PhysicsShapeQueryParameters2D.new()
	shapecast_query_params.exclude = [self]
	shapecast_query_params.shape_rid = $PhysicsBox.shape
	shapecast_query_params.transform = get_global_transform()
	var fall_offset = FALL_CHECK_OFFSET
	fall_offset.x *= move_direction
	shapecast_query_params.transform.origin += fall_offset 
	var shapecast_result = space_state.intersect_shape(shapecast_query_params)
	for hit_obj in shapecast_result:
		if hit_obj.collider is TileMap:
			return false # found land, will not fall
	return true # Not found land, will fall

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		move_and_slide()
	# Movement logic when on the ground
	else:
		# Handle  fall test to turn around. 
		var turn = _fall_test(delta)
		if turn:
			move_direction *= -1
		# Move and turn next time if we collided.
		# TODO attack player
		move_and_slide()
		if get_last_motion().x == 0:
			move_direction *= -1

		# TODO detect and seek the player
		velocity.x = move_direction * SPEED

func _process(_delta):
	# Animation logic update
	if hitpoints <= 0:
		$AnimatedSprite2D.play("dead")
	elif is_on_floor():
		if velocity.x != 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	else:
		if velocity.y > 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")

	# Sprite visual update
	if velocity.x != 0:
		$AnimatedSprite2D.set_flip_h(move_direction < 0)
