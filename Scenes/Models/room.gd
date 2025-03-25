extends Node2D
class_name Room

static var visible_threat_rooms: Array[Room] = []
var is_destroyed = false;
var has_turret: bool;
var turret_pos: Vector2i;
@export var gives_item: Drone.Items;
var active_threats = [[], [], [], []];
var visible_threats = [false, false, false, false];
var neighbours: Array[Room] = [];
var doors: Array[Door] = [];
var is_start = false;
var is_destination = false;
var is_turret_active = false;
var is_powered = true;
var is_turret_attacking = false;
var is_turret_connected = false;
var turret_attack_queue = [];

func _ready() -> void:
	$Area2D.connect("body_entered", _on_body_entered);
	$Label.text = name;

func destroy():
	Dialogues.send_terminal_response("room_destroyed", [name]);
	$Label.visible = false;
	if (GameManager.current_room == self):
		if (GameManager.doing_ending):
			GameManager.drone_instance.global_position = GameManager.prev_room.global_position;
		else:
			GameManager.drone_instance.die();
	for door in doors:
		door._neighbour_room_destroyed();
		GameManager.current_zone._update_door(door);
	for threat_type in active_threats:
		while (len(threat_type) > 0):
			threat_type[0].die();
	GameManager.current_zone.erase_room(self);
	is_destroyed = true;

func _turret_check():
	if (is_turret_active):
		for threat_type in active_threats:
			for threat in threat_type:
				if (threat and threat not in turret_attack_queue):
					turret_attack_queue.append(threat);	
		if (GameManager.current_room == self and GameManager.drone_instance not in turret_attack_queue and not GameManager.drone_instance.is_destroyed):
			turret_attack_queue.append(GameManager.drone_instance);
		if (turret_attack_queue.size() > 0 and not is_turret_attacking):
			$TurretTimer.start();
			is_turret_attacking = true;

func _on_turret_timer_timeout() -> void:
	if (not is_turret_active):
		turret_attack_queue.clear();
		return;
	turret_attack_queue[0].die();
	turret_attack_queue.remove_at(0);
	Dialogues.send_terminal_response("turret_elim", [name]);
	if (turret_attack_queue.size() > 0):
		$TurretTimer.start();
	else:
		is_turret_attacking = false;

func get_bounding_top_left_pos():
	var coll_shape = $Area2D/CollisionShape2D;
	return Vector2i(coll_shape.global_position.x - coll_shape.shape.size.x / 2, coll_shape.global_position.y - coll_shape.shape.size.y / 2);

func get_bounding_size():
	return $Area2D/CollisionShape2D.shape.size;

func _all_false_visible_threats():
	for i in range(4):
		if (visible_threats[i]): return false;
	return true;

func enable_visible_threat(threat: GameManager.Creatures):
	visible_threats[threat] = true;
	if (not _all_false_visible_threats()):
		visible_threat_rooms.append(self);

func disable_visible_threat(threat: GameManager.Creatures):
	visible_threats[threat] = false;
	if (_all_false_visible_threats()):
		visible_threat_rooms.erase(self);

func toggle_turret():
	if (not is_turret_connected):
		GameManager.drone_instance.connect_turret(self);
		return;

	is_turret_active = !is_turret_active;
	GameManager.current_zone._update_turret(self);
	Dialogues.send_terminal_response("turret_toggle", [name, "on" if is_turret_active else "off"]);

func _on_body_entered(body: Node2D):
	if (body is Drone):
		if (GameManager.current_room):
			GameManager.current_room._reset_contacts();
		GameManager.prev_room = GameManager.current_room;
		GameManager.current_room = self;
		TerminalController.update_location();
		_check_give_item();
		_check_destination();
	# _check_threats();

func _check_threats():
	var instant_death_queue = [];
	for threat_type in active_threats:
		for threat in threat_type:
			if (threat and is_instance_valid(threat)):
				if (not threat.has_contacted):
					threat.has_contacted = true;
					threat.drone_contact();
				if (GameManager.doing_ending):
					instant_death_queue.append(threat);
					TerminalController.dialogues_to_messages([[0, TerminalController.Chars.DRONE, "%s threats left." % (GameManager.get_all_threats_left() + 1)]]);
					var ending_dialogue = Dialogues.get_ending_dialogue();
					if (ending_dialogue):
						TerminalController.dialogues_to_messages(ending_dialogue);
				else:
					GameManager.create_safe_timer(0.25, func():
						if (threat and GameManager.can_drone_attack()):
							TerminalController.dialogues_to_messages(Dialogues.get_progress_dialogue("THREAT_ELIMINATED"));
							threat.die();
					);
	while (len(instant_death_queue) > 0):
		instant_death_queue[0].die();
		instant_death_queue.remove_at(0);

func _reset_contacts():
	for threat_type in active_threats:
		for threat in threat_type:
			if (threat and is_instance_valid(threat)):
				threat.has_contacted = false;

func _toggle_power(status: bool):
		#for door in doors:
		#	door.is_disabled = !status;
		is_powered = status;

func _neighbour_door_opened(which: Room):
	for volo in Volo.Instances[GameManager.current_zone_idx]:
		if (volo.current_room == which):
			volo.start_moving_to(self);

# not sorry anymore
func _check_give_item():
	var items = Drone.Items;
	var drone = GameManager.drone_instance;
	if (gives_item == items.SCANNER and not items.SCANNER in drone.collected_items):
		drone.collected_items.append(items.SCANNER);
		TerminalController.dialogues_to_messages(Dialogues.SCANNER);
		TerminalController.add_command("scan");
	elif (gives_item == items.CREATURES_LOG and not items.CREATURES_LOG in drone.collected_items):
		drone.collected_items.append(items.CREATURES_LOG);
		TerminalController.dialogues_to_messages(Dialogues.CREATURES_LOG);
		TerminalController.add_command("creatures")
	elif (gives_item == items.WEAPON and not items.WEAPON in drone.collected_items):
		drone.collected_items.append(items.WEAPON);
		await TerminalController.dialogues_to_messages(Dialogues.WEAPON);
		drone.has_weapon = true;

func _check_destination():
	print("Checking destination");
	if (is_start and GameManager.drone_instance.doing_ending):
		if (GameManager.current_zone_idx == 1):
			GameManager.show_ending();
		else:
			GameManager.regress_zone();
	elif (is_destination and not GameManager.doing_ending):
		if (GameManager.current_zone_idx == GameManager.TOTAL_ZONES):
			GameManager.finale_sequence();
		else:
			GameManager.progress_zone();

func _on_turret_check_timer_timeout() -> void:
	_turret_check();
