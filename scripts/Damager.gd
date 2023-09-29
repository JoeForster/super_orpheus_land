extends Area2D

const DEFAULT_DAMAGE = 10

@export var damage_on_hit = DEFAULT_DAMAGE

func _on_hurt_box_body_entered(body: Node2D):
	if body.is_in_group("player"):
		body.on_enemy_hit(global_position)
		body.take_damage(damage_on_hit)
