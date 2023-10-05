extends Node2D

@export var score = 100
@export var equip = PlayerState.EQUIP_TYPE.NOTHING

func _on_pickup_body_entered(_body):
	queue_free()


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		var picked_up = body.try_pickup_item(score, equip)
		if picked_up:
			queue_free()
