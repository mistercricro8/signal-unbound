extends CharacterBody2D
class_name Mira

const BASE_SPEED = 40
const BASE_ATTACK_TIME = 7.0
var speed: float
var attack_time: float
var dest: Node2D
var current_room: Room
var attacking_door: Door
var has_contacted = false
var registered = false
@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	GameManager.create_safe_timer(0.1, func():
		dest = GameManager.drone_instance;
		_on_move_timer_timeout();
	);
	GameManager.connect("_difficulty_changed", _on_difficulty_changed);

func _physics_process(_delta: float) -> void:
		_do_pathfinding();

func _do_pathfinding() -> void:
	var current_pos = global_position;
	var next_pos = agent.get_next_path_position();
	var new_vel = current_pos.direction_to(next_pos) * speed;
	_on_navigation_agent_2d_velocity_computed(new_vel);
	move_and_slide();

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity;

func _on_difficulty_changed():
	speed = GameManager.apply_difficulty(BASE_SPEED, true);
	attack_time = GameManager.apply_difficulty(BASE_ATTACK_TIME, false);

func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent();
	if (parent is Room):
		var room = parent as Room;
		if (current_room):
			current_room.active_threats[GameManager.Creatures.MIRA].erase(self);
		current_room = room;
		if (not registered):
			registered = true;
			GameManager.register_creature(self);
		current_room.active_threats[GameManager.Creatures.MIRA].append(self);
	elif (parent is Door):
		attacking_door = parent as Door;
		$AttackTimer.start(attack_time);

func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent();
	if (parent is Door):
		attacking_door = null;

func _on_attack_timer_timeout() -> void:
	if (attacking_door and not GameManager.drone_instance.is_destroyed):
		attacking_door.take_damage();
		$AttackTimer.start(attack_time);

func _on_move_timer_timeout() -> void:
	if (GameManager.drone_instance.is_destroyed):
		agent.target_position = global_position;
		return;
	agent.target_position = dest.global_position;

func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body is Drone):
		GameManager.drone_instance.die();

func die():
	MainGame.Instance.audio_kill.play();
	current_room.active_threats[GameManager.Creatures.MIRA].erase(self);
	GameManager.delete_creature(self);
	queue_free();

func drone_contact():
	pass;
