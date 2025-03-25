extends Node2D

var current_room: Room
const BASE_EXPLODE_TIME = 5.0
var explode_time: float
var has_contacted = false;
var exploding = false;
var registered = false;

func _ready() -> void:
	GameManager.connect("_difficulty_changed", _on_difficulty_changed);

func _on_explode_timer_timeout() -> void:
	current_room.destroy();
	MainGame.Instance.audio_explode.play();
	queue_free();

func _on_difficulty_changed():
	explode_time = GameManager.apply_difficulty(BASE_EXPLODE_TIME, false);

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Room):
		var room = area.get_parent() as Room;
		current_room = room;
		if (not registered):
			registered = true;
			GameManager.register_creature(self);
		room.active_threats[GameManager.Creatures.BURO].append(self);

func drone_contact():
	Dialogues.send_terminal_response("buro", []);
	if (not exploding):
		$ExplodeTimer.start(explode_time);
		exploding = true;

func die():
	current_room.active_threats[GameManager.Creatures.BURO].erase(self);
	MainGame.Instance.audio_kill.play();
	GameManager.delete_creature(self);
	if (not exploding):
		$ExplodeTimer.start(explode_time);
		exploding = true;
