extends Node2D
class_name Powa

const BASE_STUN_TIME = 4.0
var stun_time: float
var has_contacted = false
var registered = false
var current_room: Room

func _ready() -> void:
	GameManager.connect("_difficulty_changed", _on_difficulty_changed);

func _on_difficulty_changed():
	stun_time = GameManager.apply_difficulty(BASE_STUN_TIME, true);

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Room):
		var room = area.get_parent() as Room;
		current_room = room;
		if (not registered):
			registered = true;
			GameManager.register_creature(self);
		room.active_threats[GameManager.Creatures.POWA].append(self);
		room._toggle_power(false);

func drone_contact():
	GameManager.drone_instance.force_reboot(stun_time);

func die():
	MainGame.Instance.audio_kill.play();
	current_room.active_threats[GameManager.Creatures.POWA].erase(self);
	GameManager.delete_creature(self);
	current_room._toggle_power(true);
	queue_free();
