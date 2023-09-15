extends TileMap

const LAYER_HITPOINTS = "hitpoints"
const LAYER_DAMAGE = "damage"
const GROUND_LAYER_INDEX = 0

var terrain_health_map : Dictionary

func get_tile_damage(global_pos: Vector2):
	var local_pos = to_local(global_pos)
	var local_coords = local_to_map(local_pos)
	var tile_data = get_cell_tile_data(GROUND_LAYER_INDEX, local_coords)
	if tile_data != null:
		return tile_data.get_custom_data(LAYER_DAMAGE)
	else:
		return 0

func dig(global_pos: Vector2):
	var dig_local_pos = to_local(global_pos)
	var dig_local_coords = local_to_map(dig_local_pos)

	var tile_hitpoints = terrain_health_map.get(dig_local_coords)
	if tile_hitpoints == null:
		tile_hitpoints = -1
		var tile_data = get_cell_tile_data(GROUND_LAYER_INDEX, dig_local_coords)
		if tile_data != null:
			tile_hitpoints = tile_data.get_custom_data(LAYER_HITPOINTS)

	if tile_hitpoints > 0:
		tile_hitpoints -= 1

	if tile_hitpoints == 0:
		erase_cell(GROUND_LAYER_INDEX, dig_local_coords)
		terrain_health_map.erase(dig_local_coords)
	else:
		terrain_health_map[dig_local_coords] = tile_hitpoints

	print("tile_hitpoints: ", tile_hitpoints)
