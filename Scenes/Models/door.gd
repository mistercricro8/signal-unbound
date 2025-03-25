extends Node2D
class_name Door

const damage_messages = [
	"was destroyed",
	"took severe damage",
	"took light damage"
];

@export var is_safety_locked = false;
@export var rotate_sprite = false;
@onready var label := $Label;
var error_chance = 0.1;
var is_open = false;
var hits = 3;
var set_up = false;
var is_destroyed = false;
var room_conn_1: Room
var room_conn_2: Room

func _ready() -> void:
	label.text = name;
	if (rotate_sprite):
		GameManager.create_safe_timer(0.01, func():
			var label_size = label.size;
			label.pivot_offset = Vector2(label_size.x / 2, label_size.y / 2);
			label.rotation_degrees = -90;
		);
	var conn_area = get_node_or_null("Area2D");
	if (conn_area):
		conn_area.connect("area_entered", _on_area_entered);

# HASHASHH look i've got no better idea atm im really sorry
func _on_area_entered(area: Area2D):
	if (not set_up):
		var room = area.get_parent() as Room;
		if (not room_conn_1):
			room_conn_1 = room;
		else:
			room_conn_2 = room;
			room.neighbours.append(room_conn_1);
			room.doors.append(self);
			room_conn_1.neighbours.append(room);
			room_conn_1.doors.append(self);
			set_up = true;

func try_toggle():
	if (is_destroyed or is_safety_locked):
		Dialogues.send_terminal_response("door_noresponsive", [name]);
		return;
	is_open = !is_open;
	if (is_open):
		_warn_neighbours_door_opened();
	else:
		pass
	Dialogues.send_terminal_response("door_toggled", [name, ("on" if is_open else "off")]);
	if (randf() < error_chance):
		take_damage();
	return;

func _neighbour_room_destroyed():
	is_open = false;
	is_safety_locked = true;

func _warn_neighbours_door_opened():
	room_conn_1._neighbour_door_opened(room_conn_2);
	room_conn_2._neighbour_door_opened(room_conn_1);
	
func take_damage(dmg: int = 1):
	if (not is_destroyed):
		hits -= dmg;
		if (hits <= 0):
			is_destroyed = true;
			is_open = true;
			MainGame.Instance.audio_doors.play();
			# label.modulate = Color.WHITE;
			_warn_neighbours_door_opened();
			GameManager.current_zone._update_door(self);
			hits = 0;
		Dialogues.send_terminal_response("door_damage", [name, damage_messages[hits]]);
