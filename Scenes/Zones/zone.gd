extends Node2D
class_name Zone

static var doing_ending = false;
const SOURCE_ID = 2;
const DRONE_ATLAS_POS = Vector2i(0, 2);
const BG_ATLAS_POS = Vector2i(0, 0);
const DOOR_ATLAS_POS = Vector2i(2, 0);
const TURRET_ATLAS_POS = Vector2i(0, 3);
const SCAN_ATLAS_POS = Vector2i(0, 5);
@onready var threat_layers = [$ThreatsLayer, $ThreatsLayer2, $ThreatsLayer3, $ThreatsLayer4];
@export var destination_room: Room;
@export var start_room: Room;
var drone_tilemap_pos: Vector2i;

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	GameManager.load_rooms_under_node($Rooms);
	GameManager.load_doors_under_node($Doors);
	GameManager.set_drone_instance($Drone);
	if (doing_ending):
		GameManager.drone_instance.global_position = destination_room.global_position;
		MainCamera.Instance.reposition_to_obj(destination_room);
		GameManager.create_safe_timer(1, func():
			GameManager.drone_instance.finale_sequence();
		);
		MainGame.Instance.heart_beat._change_inner_pct((4 - GameManager.current_zone_idx) * 0.33);
		MainGame.Instance.heart_beat.pitch_scale += 0.25;
	else:
		MainCamera.Instance.reposition_to_obj($CameraFocus);
	_on_drone__update_position();
	destination_room.is_destination = true;
	start_room.is_start = true;
	
func mark_room_as_threat(room: Room, creature: GameManager.Creatures):
	var layer = threat_layers[creature];
	var atlas_pos = Vector2i(SCAN_ATLAS_POS.x + creature, SCAN_ATLAS_POS.y);
	_for_all_cells_in_room(room, layer, func (cell): layer.set_cell(cell, SOURCE_ID, atlas_pos));
	room.enable_visible_threat(creature);
	
func clear_room_threat(room: Room, creature: GameManager.Creatures):
	var layer = threat_layers[creature];
	_for_all_cells_in_room(room, layer, func (cell): layer.erase_cell(cell));
	room.disable_visible_threat(creature);

func clear_all_room_threats(room: Room):
	for i in range(4):
		clear_room_threat(room, i);
	
func _for_all_cells_in_room(room: Room, layer: TileMapLayer, callback: Callable):
	var pos = layer.local_to_map(layer.to_local(room.get_bounding_top_left_pos()));
	var shape = room.get_bounding_size();
	for i in range(0, (shape.x / layer.tile_set.tile_size.x) + 1):
		for j in range(0, (shape.y / layer.tile_set.tile_size.y) + 1):
			var cell = Vector2i(pos.x + i, pos.y + j);
			callback.call(cell);

# good job documenting this
func toggle_doors(whichs: Array[String]):
	for which in whichs:
		if (which not in GameManager.doors):
			Dialogues.send_terminal_response("invalid_door", [which]);
			return;
		var door = GameManager.doors[which] as Door;
		door.try_toggle();
		_update_door(door);

func _update_door(which: Door):
	var door_pos = $WorldLayer.local_to_map($WorldLayer.to_local(which.global_position));
	var alternative_tile = $WorldLayer.get_cell_alternative_tile(door_pos);
	var new_sprite_x;
	if (which.is_destroyed and which.is_safety_locked):
		new_sprite_x = DOOR_ATLAS_POS.x + 3;
	elif (which.is_destroyed):
		new_sprite_x = DOOR_ATLAS_POS.x + 2;
	else:
		new_sprite_x = DOOR_ATLAS_POS.x + int(!which.is_open);
	$WorldLayer.set_cell(door_pos, SOURCE_ID, Vector2i(new_sprite_x, DOOR_ATLAS_POS.y), alternative_tile);

func _update_turret(room: Room):
	var turret_pos = room.turret_pos;
	var new_sprite_x = TURRET_ATLAS_POS.x + int(room.is_turret_active) * 2; # boom
	$EntitiesLayer.set_cell(turret_pos, SOURCE_ID, Vector2i(new_sprite_x, TURRET_ATLAS_POS.y));

func toggle_turret(which: String):
	if (which not in GameManager.rooms):
		Dialogues.send_terminal_response("invalid_room", [which]);
		return;
	var room = GameManager.rooms[which] as Room;
	if (not room.has_turret):
		Dialogues.send_terminal_response("room_no_turret", [which]);
		return;
	if (not room.is_powered):
		Dialogues.send_terminal_response("turret_unresponsive", [which]);
		return;
	room.toggle_turret();

func print_dest():
	Dialogues.send_terminal_response("access", [destination_room.name]);

func _get_turret_tilemap_pos(real_pos: Vector2):
	return $EntitiesLayer.local_to_map($EntitiesLayer.to_local(real_pos));

func finale_sequence():
	doing_ending = true;
	
func _on_drone__update_position() -> void:
	if (GameManager.drone_instance and !GameManager.drone_instance.is_destroyed):
		if (drone_tilemap_pos):
			$EntitiesLayer.erase_cell(drone_tilemap_pos);
		drone_tilemap_pos = $EntitiesLayer.local_to_map($EntitiesLayer.to_local($Drone.global_position));
		$EntitiesLayer.set_cell(drone_tilemap_pos, SOURCE_ID, DRONE_ATLAS_POS);

func erase_drone():
	$EntitiesLayer.erase_cell(drone_tilemap_pos);

func erase_room(room: Room):
	_for_all_cells_in_room(room, $WorldLayer, func (cell): $WorldLayer.erase_cell(cell));
	if (room.has_turret):
		$EntitiesLayer.erase_cell(room.turret_pos);
