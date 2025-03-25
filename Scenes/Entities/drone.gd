extends CharacterBody2D
class_name Drone

enum Items { NONE, SCANNER, WEAPON, CREATURES_LOG }
static var collected_items = []
var SCANNER_FAILURE_CHANCES = [0, 0, 0, 0.01, 0.03]
var ENDING_FAILURE_CHANCES = [0, 0.28, 0.2, 0.1, 0.06]
const TURRET_CONNECTION_MSGS = [
	"Requesting connection to turret...",
	"Verifying security token...",
	"Deserializing turret data...",
	"Switching to internal turret protocol...",
	"Flushing turret connection cache...",
	""
]
const BASE_SPEED = 140
var speed: float
var is_moving = false
var is_scanning = false
var is_disabled = false
var is_connecting = false
var force_cancel_connection = false
var doing_ending = false
var ending_ending = false
static var has_weapon = false
var dest: Node2D
var pathfind_queue: Array
var is_destroyed = false
@onready var agent: NavigationAgent2D = $NavigationAgent2D

signal _update_position

func _ready() -> void:
	emit_signal("_update_position");
	GameManager.connect("_difficulty_changed", _on_difficulty_changed);

func _on_difficulty_changed():
	speed = GameManager.apply_difficulty(BASE_SPEED, false);

func _physics_process(_delta: float) -> void:
	if (is_moving and not is_disabled and not is_destroyed):
		_do_pathfinding();
	
func _do_pathfinding():
	var current_pos = global_position
	var next_pos = agent.get_next_path_position();
	var new_vel = current_pos.direction_to(next_pos) * speed;
	_on_navigation_agent_2d_velocity_computed(new_vel);
	move_and_slide();

func die():
	if (is_destroyed or doing_ending):
		return;
	MainGame.Instance.audio_drone_die.play();
	is_destroyed = true;
	GameManager.set_difficulty(GameManager.global_difficulty - 1);
	_disable_scanning();
	GameManager.current_zone.erase_drone();
	await TerminalController.dialogues_to_messages(Dialogues.get_progress_dialogue("DESTROYED"));
	GameManager.create_safe_timer(5, func():
		GameManager.reset_zone();
	);
	
func start_moving_to(p_dest: String, force: bool, type: String = "room"):
	if (p_dest not in GameManager.rooms and p_dest not in GameManager.doors):
		Dialogues.send_terminal_response("invalid_code", [type]);
		return;
	var n_dest = GameManager.rooms[p_dest] if type == "room" else GameManager.doors[p_dest];
	if (force):
		pathfind_queue.clear();
	pathfind_queue.append(n_dest);
	if (len(pathfind_queue) <= 1):
		Dialogues.send_terminal_response("movement", [("Forcing" if force else "Starting"), type, p_dest]);
		_set_dest_and_start_pathfind(n_dest);
	else:
		Dialogues.send_terminal_response("movement_queue", [type, p_dest]);

func _set_dest_and_start_pathfind(p_dest: Node2D):
	dest = p_dest;
	is_moving = true;
	_disable_scanning();
	_passive_relocate_dest();

func _passive_relocate_dest():
	if (is_moving):
		agent.target_position = dest.global_position;
		if (!agent.is_target_reachable()):
			pathfind_queue.clear();
			Dialogues.send_terminal_response("unreachable", []);
			if (doing_ending):
				GameManager.drone_instance.global_position = GameManager.prev_room.global_position;
				if (!agent.is_target_reachable()):
					GameManager.drone_instance.global_position = GameManager.current_room.global_position;
				GameManager.create_safe_timer(0.25, func():
					_move_to_closest_threat();
				);
			else:
				is_moving = false;

func _passive_update_position():
	if (is_moving):
		emit_signal("_update_position");

func cancel_turret_connection():
	if (not is_connecting):
		Dialogues.send_terminal_response("no_turret_connection", []);
		return;
	force_cancel_connection = true;
	Dialogues.send_terminal_response("cancelled_turret_conn", []);

func connect_turret(room: Room):
	Dialogues.send_terminal_response("turret_conn", [room.name]);
	is_disabled = true;
	is_connecting = true;
	force_cancel_connection = false;
	var duration = randi_range(9, 15);
	for i in range(3, duration, 3):
		GameManager.create_safe_timer(i, func():
			if (not is_destroyed and not force_cancel_connection):
				TerminalController.send_type_message(TURRET_CONNECTION_MSGS[i / 3 - 1], TerminalController.MessageTypes.SUCCESS, false, true);
		);
	GameManager.create_safe_timer(duration, func():
		if (not is_destroyed and not force_cancel_connection):
			is_disabled = false;
			is_connecting = false;
			room.is_turret_connected = true;
			room.toggle_turret();
	);

func _move_to_closest_threat():
	var creatures = GameManager.creature_instances[GameManager.current_zone_idx];
	if (len(creatures) == 0):
		start_moving_to(GameManager.current_zone.start_room.name, true);
		if (GameManager.current_zone_idx == 1):
			GameManager.set_difficulty(4);
			MainGame.Instance.heart_beat.pitch_scale = 2.1;
			MainGame.Instance.heart_beat._change_inner_pct(1.33);
			ending_ending = true;
		return;
	var closest_threat = null;
	var closest_dist = 999999;
	for creature in creatures:
		var dist = global_position.distance_to(creature.global_position);
		if (dist < closest_dist):
			closest_dist = dist;
			closest_threat = creature;
	if (closest_threat):
		start_moving_to(closest_threat.current_room.name, true);

func _disable_scanning():
	if (not doing_ending):
		is_scanning = false;
		while (len(Room.visible_threat_rooms) > 0):
			GameManager.current_zone.clear_all_room_threats(Room.visible_threat_rooms[0]);

func force_reboot(duration: float):
	if (doing_ending):
		return;
	Dialogues.send_terminal_response("rebooting", []);
	is_disabled = true;
	GameManager.create_safe_timer(duration, func():
		if (not is_destroyed):
			is_disabled = false;
			Dialogues.send_terminal_response("rebooted", []);
	);

func start_scan():
	pathfind_queue.clear();
	if (not doing_ending):
		is_moving = false;
	is_scanning = true;
	Dialogues.send_terminal_response("scan", []);
	
func finale_sequence():
	doing_ending = true;
	$NavigationAgent2D.navigation_layers = enable_bitmask_inx($NavigationAgent2D.navigation_layers, 1);
	_move_to_closest_threat();
	start_scan();

func enable_bitmask_inx(_bitmask: int, _index: int) -> int:
	return _bitmask | (1 << _index)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity;

func _on_navigation_agent_2d_target_reached() -> void:
	pathfind_queue.remove_at(0);
	_passive_update_position();
	if (doing_ending):
		is_moving = false;
		if (GameManager.current_room != GameManager.current_zone.start_room):	
			GameManager.create_safe_timer(0.25, func():
				_move_to_closest_threat();
			);
	else:
		if (len(pathfind_queue) > 0):
			_set_dest_and_start_pathfind(pathfind_queue[0]);
		else:
			is_moving = false;

func _on_move_timer_timeout() -> void:
	_passive_relocate_dest();
	_passive_update_position();
	if (ending_ending):
		TerminalController.dialogues_to_messages([[0, TerminalController.Chars.DRONE, "1 threat left"]]);
		TerminalController.send_type_message("1 threat left", TerminalController.MessageTypes.ERROR);

func _on_scan_timer_timeout() -> void:
	if (is_scanning):
		for neighbour in GameManager.current_room.neighbours + [GameManager.current_room]:
			for threat_type in range(4):
				if (len(neighbour.active_threats[threat_type]) == 0 and neighbour.visible_threats[threat_type]):
					GameManager.current_zone.clear_room_threat(neighbour, threat_type);

				var rd = randf();
				if (len(neighbour.active_threats[threat_type]) > 0):
					if (not neighbour.visible_threats[threat_type]):
						GameManager.current_zone.mark_room_as_threat(neighbour, threat_type);
				elif ((GameManager.doing_ending and rd < ENDING_FAILURE_CHANCES[GameManager.current_zone_idx]) or (rd < SCANNER_FAILURE_CHANCES[GameManager.current_zone_idx])):
					GameManager.current_zone.mark_room_as_threat(neighbour, threat_type);
					GameManager.create_safe_timer(0.75, func():
						GameManager.current_zone.clear_room_threat(neighbour, threat_type);
					);

func _on_attack_timer_timeout() -> void:
	if (GameManager.current_room):
		GameManager.current_room._check_threats();

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (doing_ending and area.get_parent() is Door):
		GameManager.create_safe_timer(0.25, func():
			var door = area.get_parent() as Door;
			door.take_damage(3);
		);
