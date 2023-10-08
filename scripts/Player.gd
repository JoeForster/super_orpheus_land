extends CharacterBody2D

enum DAMAGE_TYPE { NORMAL, LAVA }

# Export variables (settings, were constants)
@export var MAX_HP : int
@export var MAX_EP : float
@export var EP_CHARGE_RATE : float
@export var EP_DRAIN_RATE : float
@export var SPEED : float
@export var JUMP_VELOCITY : int
@export var JUMP_BOOST_PERIOD : float
@export var JUMP_BOOST_VEL_PER_SEC : int
@export var DAMAGED_VELOCITY : float
@export var RESPAWN_TIME : float
@export var DIG_PERIOD : float
@export var DIG_OFFSET : Vector2

@export var spawn_point : Node2D
@export var hitpoints : int
@export var energypoints : float
@export var hp_bar : TextureProgressBar
@export var ep_bar : TextureProgressBar
@export var score_value : RichTextLabel
@export var hint_label : RichTextLabel
@export var hint_hide_time : float

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


var jump_boost_timer = JUMP_BOOST_PERIOD
var dig_timer = 0
var last_dig_global_pos : Vector2
var is_digging = false
var respawn_timer = 0
var hint_timer = -1
var score = 0
var last_damage_type = DAMAGE_TYPE.NORMAL
var started_death_anim = false
var inventory = [PlayerState.EQUIP_TYPE.NOTHING]
var equipped_index = 0
var is_playing_music = false
var music_pos = 0.0
var music_player : AudioStreamPlayer = null
var music_min_vol = -40.0
var music_target_vol
var music_fade_rate = 20.0

func _enter_tree():
	music_player = $"/root/WorldRoot/MusicPlayer"
	music_target_vol = music_player.volume_db
	music_player.volume_db = music_min_vol
	music_player.stream_paused = true
	
	hitpoints = MAX_HP
	energypoints = MAX_EP
	position = spawn_point.position

func reset_world():
	# TODO manage flow separate from player script
	get_tree().reload_current_scene()

func take_damage(amount : int, damage_type : DAMAGE_TYPE = DAMAGE_TYPE.NORMAL):
	if hitpoints > 0:
		hitpoints -= amount
	last_damage_type = damage_type
	return hitpoints > 0


func _update_dig(delta):
	dig_timer -= delta
	if dig_timer <= 0:
		dig_timer = DIG_PERIOD
		# Do a raycast diagonally to attempt a dig in front of the character
		var space_state = get_world_2d().direct_space_state
		var dig_offset_oriented = DIG_OFFSET
		if $AnimatedSprite2D.is_flipped_h():
			dig_offset_oriented.x *= -1
		var raycast_query = PhysicsRayQueryParameters2D.create(global_position, global_position + dig_offset_oriented)
		raycast_query.exclude = [self]
		var raycast_result = space_state.intersect_ray(raycast_query)
		if not raycast_result.is_empty():
			var tilemap_collided = raycast_result.collider as TileMap
			if tilemap_collided != null:
				last_dig_global_pos = raycast_result.position
				tilemap_collided.dig(last_dig_global_pos)
				return true
	return false

func _is_alive():
	return hitpoints > 0

func _get_equipped_item():
	return inventory[equipped_index]

func _update_controls(delta):
	# Handle Jump.
	if is_on_floor():
		jump_boost_timer = JUMP_BOOST_PERIOD
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	elif Input.is_action_pressed("jump"):
		if jump_boost_timer > 0.0:
			jump_boost_timer = jump_boost_timer - delta
			velocity.y += JUMP_BOOST_VEL_PER_SEC * delta
		else:
			jump_boost_timer = 0.0

	# Handle equipment use
	if Input.is_action_just_pressed("switch"):
		equipped_index = equipped_index + 1
		if equipped_index >= inventory.size():
			equipped_index = 0

	var equipped = _get_equipped_item()
	if equipped == PlayerState.EQUIP_TYPE.PICKAXE:
		$Equip/Lyre.hide()
		$Equip/Pickaxe.show()
		is_playing_music = false
		if Input.is_action_pressed("use"):
			is_digging = _update_dig(delta)
		else:
			is_digging = false
		
	elif equipped == PlayerState.EQUIP_TYPE.LYRE:
		$Equip/Lyre.show()
		$Equip/Pickaxe.hide()
		is_digging = false
		if energypoints < 1.0:
			is_playing_music = false
		elif Input.is_action_just_pressed("use"):
			is_playing_music = true
		elif Input.is_action_just_released("use"):
			is_playing_music = false
	else:
		# TODO use inventory array instead and separate show/hide from equip-specific logic above
		is_playing_music = false
		is_digging = false
		$Equip/Lyre.hide()
		$Equip/Pickaxe.hide()


	# Player can walk as long as they're not playing the lyre
	var direction = Input.get_axis("move_left", "move_right")
	if direction and not is_playing_music:
		#print("left/right input: ", direction)
		velocity.x = direction * SPEED
	else:
		#print("left/right input: 0")
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _update_equip_effects(delta):
		
	$Equip/Lyre/MusicParticles.emitting = is_playing_music
	if is_playing_music:
		music_player.stream_paused = false
		if music_player.volume_db < music_target_vol:
			music_player.volume_db += delta * music_fade_rate
		if music_player.volume_db >= music_target_vol:
			music_player.volume_db  = music_target_vol
	else:
		if music_player.volume_db > music_min_vol:
			music_player.volume_db -= delta * music_fade_rate
		if music_player.volume_db <= music_min_vol:
			music_player.volume_db = music_min_vol
			music_player.stream_paused = true
			
	$Equip/Pickaxe/DigParticles.emitting = is_digging
	if is_digging:
		$Equip/Pickaxe/DigParticles.global_position = last_dig_global_pos


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# CONTROLS
	# TODO should be in process, but does mess with velocity directly!

	if _is_alive():
		_update_controls(delta)
	else:
		is_playing_music = false
		if last_damage_type == DAMAGE_TYPE.LAVA:
			velocity = Vector2.ZERO # Stop moving as we're doing the sink anim
		
	_update_equip_effects(delta)

	move_and_slide()
	
	if is_on_floor():
		var floor_collision : KinematicCollision2D = get_last_slide_collision()
		if floor_collision != null:
			var tilemap_collided = floor_collision.get_collider() as TileMap
			if tilemap_collided != null:
				var hit_global_pos = floor_collision.get_position()
				var damage_taken = tilemap_collided.get_tile_damage(hit_global_pos)
				if damage_taken > 0:
					var still_alive = take_damage(damage_taken, DAMAGE_TYPE.LAVA)
					if still_alive:
						on_enemy_hit(hit_global_pos)

func _process(delta):
	# Energy charge/drain
	if is_playing_music:
		energypoints -= delta * EP_DRAIN_RATE
		if energypoints < 0:
			energypoints = 0
	else:
		energypoints += delta * EP_CHARGE_RATE
		if energypoints > MAX_EP:
			energypoints = MAX_EP
		
	
	# Animation logic update
	if not _is_alive():
		if not started_death_anim:
			if last_damage_type == DAMAGE_TYPE.LAVA:
				$AnimatedSprite2D.play("lava")
			else:
				$AnimatedSprite2D.play("dead")
			started_death_anim = true
			
		respawn_timer += delta
		if respawn_timer >= RESPAWN_TIME:
			respawn_timer = 0
			reset_world()
		
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
		var facing_left = velocity.x < 0
		$AnimatedSprite2D.set_flip_h(facing_left)
		$Equip.set_scale(Vector2(-1 if facing_left else 1, 1))


	# HUD update
	if hp_bar != null:
		hp_bar.set_value_no_signal(hitpoints);
	if ep_bar != null:
		ep_bar.set_value_no_signal(energypoints);
	if score_value != null:
		score_value.text = str(score)

	if Input.is_anything_pressed() and hint_timer == -1:
		hint_timer = hint_hide_time
	if hint_timer > 0:
		hint_timer -= delta
		if hint_timer <= 0:
			hint_timer = 0
			hint_label.hide()
			
	if Input.is_action_just_released("restart"):
		reset_world()
	elif Input.is_action_just_released("quit"):
		get_tree().quit()

func try_pickup_item(score_to_add : int, equip_to_add : PlayerState.EQUIP_TYPE):
	if _is_alive():
		score += score
		if not inventory.has(equip_to_add):
			equipped_index = inventory.size()
			inventory.push_back(equip_to_add)
		return true
	else:
		return false
	
func on_enemy_hit(hitter_global_position: Vector2):
	var bounce_dir : Vector2 = global_position - hitter_global_position
	if bounce_dir.is_zero_approx():
		bounce_dir = Vector2(0, -1)
	bounce_dir = bounce_dir.normalized()
	bounce_dir.y -= 1
	bounce_dir = bounce_dir.normalized()

	velocity = bounce_dir * DAMAGED_VELOCITY
