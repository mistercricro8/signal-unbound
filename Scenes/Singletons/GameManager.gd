extends Node

var rooms: Dictionary;
var doors: Dictionary;
var drone_instance: Drone;

const TOTAL_ZONES = 4
var zones = [
	null,
	preload("res://Scenes/Zones/Zone1.tscn"),
	preload("res://Scenes/Zones/Zone2.tscn"),
	preload("res://Scenes/Zones/Zone3.tscn"),
	preload("res://Scenes/Zones/Zone4.tscn")
]
var zone_instances = [
	null
]
var creature_instances = [null ,[], [], [], []]
var global_difficulty = 0
var current_zone: Zone
var current_zone_idx = 1
var current_room: Room
var prev_room: Room
var transition_rect: ColorRect
var doing_ending = false
var total_threats: int
static var game_completed = false;
enum Creatures { VOLO, POWA, MIRA, BURO }

signal _difficulty_changed

func _setup(p_transition_rect: ColorRect):
	transition_rect = p_transition_rect
	for i in range(1, TOTAL_ZONES + 1):
		zone_instances.append(zones[i].instantiate());
	change_zone();
	TerminalController.dialogues_to_messages(Dialogues.INTRO);

func show_ending():
	transition_rect.visible = true;
	drone_instance.ending_ending = false;
	game_completed = true;
	MainGame.Instance.heart_beat.stop();
	TerminalController.cancel_all_dialogues();
	GameManager.create_safe_timer(3, func():
		while (len(zone_instances) > 1):
			zone_instances[1].queue_free();
			zone_instances.remove_at(1);
		creature_instances = [null ,[], [], [], []];
		SceneController.change_scene("main_menu");
	);

func warp_to_room(room_name: String):
	drone_instance.global_position = rooms[room_name].global_position;

func force_change_zone(to: int):
	current_zone_idx = to;
	change_zone();

func get_all_threats_left():
	var count = 0;
	for i in range(1, TOTAL_ZONES + 1):
		count += len(creature_instances[i]);
	return count;	

func set_difficulty(val: int, force = false):
	if (not force):
		val = clamp(val, -4, 4);
	global_difficulty = val;
	emit_signal("_difficulty_changed");

func reset_zone():
	Volo._clear_zone_instances();
	creature_instances[current_zone_idx].clear();
	zone_instances[current_zone_idx].queue_free();
	zone_instances[current_zone_idx] = zones[current_zone_idx].instantiate();
	change_zone();

func register_creature(instance: Node):
	creature_instances[current_zone_idx].append(instance);

func delete_creature(instance: Node):
	creature_instances[current_zone_idx].erase(instance);

func apply_difficulty(val: float, inc: bool):
	if (inc):
		return val * (1 + global_difficulty / 25.0);
	return val / (1 + global_difficulty / 25.0);

func regress_zone():
	current_zone_idx -= 1;
	TerminalController.dialogues_to_messages(Dialogues.get_progress_dialogue("ZONE_REGRESS"));
	GameManager.create_safe_timer(1.5, func():
		change_zone();
	);

func progress_zone():
	current_zone_idx += 1;
	set_difficulty(global_difficulty + 1);
	TerminalController.dialogues_to_messages(Dialogues.get_progress_dialogue("ZONE_PROGRESS"));
	GameManager.create_safe_timer(7, func():
		change_zone();
	);

func can_drone_attack():
	return drone_instance and drone_instance.has_weapon and not drone_instance.is_disabled and not drone_instance.is_destroyed;

func change_zone():
	_deferred_change_zone.call_deferred();
	
func _deferred_change_zone():
	transition_rect.visible = true;
	if (current_zone):
		get_tree().root.remove_child(current_zone);
	current_zone = zone_instances[current_zone_idx];
	current_room = null;
	get_tree().root.add_child(current_zone);
	GameManager.create_safe_timer(0.5, func():
		transition_rect.visible = false;
		TerminalController.update_location();
		TerminalController.clear_terminal();
		TerminalController.clear_messages();
		emit_signal("_difficulty_changed");
	);

func set_drone_instance(drone: Drone):
	drone_instance = drone;

func load_rooms_under_node(node: Node2D):
	rooms = {};
	for child in node.get_children():
		rooms[child.name] = child;
		
func load_doors_under_node(node: Node2D):
	doors = {};
	for child in node.get_children():
		doors[child.name] = child;

func finale_sequence():
	total_threats = get_all_threats_left();
	MainGame.Instance.audio_message._change_inner_pct(0.75);
	MainGame.Instance.audio_doors._change_inner_pct(0.75);
	MainGame.Instance.heart_beat._change_inner_pct(0);
	MainGame.Instance.heart_beat.play();
	doing_ending = true;
	set_difficulty(-12, true);
	for i in range(10):
		create_safe_timer(i * 0.2, func():
			TerminalController.send_type_message("Lost connection, reconnecting", TerminalController.MessageTypes.ERROR);
		);
	GameManager.create_safe_timer(5, func():
		TerminalController.send_type_message("Reconnected", TerminalController.MessageTypes.SUCCESS);
		TerminalController.dialogues_to_messages(Dialogues.ENDING_START);
		current_zone.finale_sequence();
		drone_instance.finale_sequence();
	);

func create_safe_timer(duration: float, callback: Callable):
	var timer = get_tree().create_timer(duration);
	timer.timeout.connect(
		func():
			if (current_zone and is_instance_valid(current_zone)):
				callback.call();
	);
