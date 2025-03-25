extends Camera2D
class_name MainCamera

static var Instance: Camera2D
var dir: Vector2
const CAMERA_SPEED = 5

func _ready() -> void:
	Instance = self; # random unity code patterns go
	
func reposition_to_obj(drone: Node2D):
	global_position = drone.global_position;	

func _physics_process(_delta: float) -> void:
	if (Input.is_action_just_pressed("camera_zoom_in")):
		zoom = Vector2(zoom.x + 0.1, zoom.y + 0.1);
	if (Input.is_action_just_pressed("camera_zoom_out")):
		zoom = Vector2(zoom.x - 0.1, zoom.y - 0.1);
	
	dir = Vector2.ZERO;
	if (Input.is_action_pressed("ui_up")):
		dir += Vector2.UP;
	if (Input.is_action_pressed("ui_down")):
		dir += Vector2.DOWN;
	if (Input.is_action_pressed("ui_right")):
		dir += Vector2.RIGHT;
	if (Input.is_action_pressed("ui_left")):
		dir += Vector2.LEFT;
		
	translate(dir.normalized() * CAMERA_SPEED);
