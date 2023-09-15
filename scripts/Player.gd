extends CharacterBody2D

const MAX_HP = 100
const INITIAL_HP = MAX_HP
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const DAMAGED_VELOCITY = 300.0
const DIG_PERIOD = 0.1
const DIG_OFFSET = Vector2(32, 32)

@export var hitpoints = INITIAL_HP
@export var hp_bar : TextureProgressBar
@export var score_value : RichTextLabel

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dig_timer = DIG_PERIOD
var score = 0

func _update_dig(delta):
	dig_timer -= delta
	if dig_timer <= 0:
		dig_timer = DIG_PERIOD
		# Do a raycast diagonally to attempt a dig in front of the character
		var space_state = get_world_2d().direct_space_state
		var raycast_query = PhysicsRayQueryParameters2D.create(global_position, global_position + DIG_OFFSET)
		raycast_query.exclude = [self]
		var raycast_result = space_state.intersect_ray(raycast_query)
		if not raycast_result.is_empty():
			var tilemap_collided = raycast_result.collider as TileMap
			if tilemap_collided != null:
				var dig_global_pos = raycast_result.position
				tilemap_collided.dig(dig_global_pos)


func _is_alive():
	return hitpoints > 0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# CONTROLS
	if _is_alive():
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Handle dig.
		if Input.is_action_pressed("dig"):
			_update_dig(delta)

		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			#print("left/right input: ", direction)
			velocity.x = direction * SPEED
		else:
			#print("left/right input: 0")
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if is_on_floor():
		var floor_collision : KinematicCollision2D = get_last_slide_collision()
		if floor_collision != null:
			var tilemap_collided = floor_collision.get_collider() as TileMap
			if tilemap_collided != null:
				var hit_global_pos = floor_collision.get_position()
				var damage_taken = tilemap_collided.get_tile_damage(hit_global_pos)
				if damage_taken > 0:
					on_enemy_hit(hit_global_pos, damage_taken)

func _process(_delta):
	# Animation logic update
	if not _is_alive():
		$AnimatedSprite2D.play("dead")
	elif is_on_floor():
		if velocity.x != 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	else:
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")

	# Sprite visual update
	if velocity.x != 0:
		$AnimatedSprite2D.set_flip_h(velocity.x < 0)

	# HUD update
	if hp_bar != null:
		hp_bar.set_value_no_signal(hitpoints);
	if score_value != null:
		score_value.text = str(score)

func try_pickup_item():
	if _is_alive():
		score += 100
		return true
	else:
		return false
	
func on_enemy_hit(hitter_global_position: Vector2, damage: int):
	var bounce_dir : Vector2 = global_position - hitter_global_position
	if bounce_dir.is_zero_approx():
		bounce_dir = Vector2(0, -1)
	bounce_dir = bounce_dir.normalized()
	bounce_dir.y -= 1
	bounce_dir = bounce_dir.normalized()

	velocity = bounce_dir * DAMAGED_VELOCITY
	
	if hitpoints > 0:
		hitpoints -= damage
