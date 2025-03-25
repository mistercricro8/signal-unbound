extends Node2D

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Room):
		var room = area.get_parent() as Room;
		room.has_turret = true;
		room.turret_pos = GameManager.current_zone._get_turret_tilemap_pos(global_position);
