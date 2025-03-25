extends CharacterBody2D
class_name Volo

static var Instances: Array = [null, [], [], [], []]
var current_room: Room
var is_moving = false;
var dest: Node2D
var has_contacted = false
var registered = false
const BASE_SPEED = 300
var speed: float
@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	Instances[GameManager.current_zone_idx].append(self);
	GameManager.connect("_difficulty_changed", _on_difficulty_changed);

func _on_difficulty_changed():
	speed = GameManager.apply_difficulty(BASE_SPEED, true);

func _physics_process(_delta: float) -> void:
	if (is_moving):
		_do_pathfinding();

func start_moving_to(p_dest: Room) -> void:
	dest = p_dest;
	is_moving = true;
	agent.target_position = dest.global_position;

func _do_pathfinding():
	var current_pos = global_position
	var next_pos = agent.get_next_path_position();
	var new_vel = current_pos.direction_to(next_pos) * speed;
	_on_navigation_agent_2d_velocity_computed(new_vel);
	move_and_slide();

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity;

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Room):
		var room = area.get_parent() as Room;
		if (current_room):
			current_room.active_threats[GameManager.Creatures.VOLO].erase(self);
		current_room = room
		if (not registered):
			registered = true;
			GameManager.register_creature(self);
		current_room.active_threats[GameManager.Creatures.VOLO].append(self);

func drone_contact():
	GameManager.create_safe_timer(0.5, func():
		if (not GameManager.can_drone_attack()):
			GameManager.drone_instance.die();
	);

func _on_navigation_agent_2d_navigation_finished() -> void:
	is_moving = false;
	
static func _clear_zone_instances(zone: int = -1):
	if (zone == -1):
		zone = GameManager.current_zone_idx;
	var current_inst = Instances[GameManager.current_zone_idx];
	while (len(current_inst) > 0):
		current_inst[0].die();

static func _clear_all_instances():
	for i in range(1, 5):
		_clear_zone_instances(i);

func die():
	MainGame.Instance.audio_kill.play();
	Instances[GameManager.current_zone_idx].erase(self);
	current_room.active_threats[GameManager.Creatures.VOLO].erase(self);
	GameManager.delete_creature(self);
	queue_free();
