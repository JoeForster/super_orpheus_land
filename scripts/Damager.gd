extends Area2D

const DEFAULT_DAMAGE = 10

func _on_hurt_box_body_entered(body: Node2D):
	if body.is_in_group("player"):
		body.on_enemy_hit(global_position)
		body.take_damage(DEFAULT_DAMAGE)
