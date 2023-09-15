extends Node2D

func _on_pickup_body_entered(_body):
	queue_free()


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		var picked_up = body.try_pickup_item()
		if picked_up:
			queue_free()
