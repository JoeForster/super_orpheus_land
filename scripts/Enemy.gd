extends CharacterBody2D

const ATTRACTED_MIN_DISTANCE = 40.0
const FALL_CHECK_OFFSET = Vector2(32, 32)

@export var hitpoints = 10
@export var is_affected_by_music = true
@export var move_speed_normal = 100.0
@export var move_speed_soothed = 60.0

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
		
		# If detecting music, be attracted by that
		var attracted_to_pos = null
		var current_move_speed
		# TODO use a layer properly so it only picks up the player
		for body in $DetectorArea2D.get_overlapping_bodies():
			if body.is_in_group("player"):
				if body.is_playing_music:
					attracted_to_pos = body.global_position
					break

		if attracted_to_pos != null:
			# If we have an attractor we should ignore fall tests
			var to_attractor = attracted_to_pos.x - global_position.x
			if abs(to_attractor) > ATTRACTED_MIN_DISTANCE:
				move_direction = sign(to_attractor)
				current_move_speed = move_speed_soothed
			else:
				current_move_speed = 0
		else:
			# If we didn't move last time, or we're about to fall, then turn.
			# TODO fix this to properly detect obstacle hit instead; attack player
			var turn = get_last_motion().x == 0 || _fall_test(delta)
			if turn:
				move_direction *= -1
			current_move_speed = move_speed_normal

		# TODO detect and seek the player
		velocity.x = move_direction * current_move_speed
		move_and_slide()

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
