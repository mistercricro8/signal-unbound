extends Node2D
class_name MainGame

@onready var audio_message: AudioPlayer = $Messages
@onready var audio_doors: AudioPlayer = $Doors
@onready var audio_explode: AudioPlayer = $Explode
@onready var audio_tercorrect: AudioPlayer = $TerCorrect
@onready var audio_terwarning: AudioPlayer = $TerWarning
@onready var audio_tererror: AudioPlayer = $TerError
@onready var audio_kill: AudioPlayer = $Kill
@onready var audio_drone_die: AudioPlayer = $DroneDie
@onready var heart_beat: AudioPlayer = $Heartbeat

static var Instance: MainGame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self;
	GameManager._setup($Camera2D/Control/Transition);
	TerminalController._setup($Camera2D/Control/ConsoleInput, $Camera2D/Control/ConsoleOutput, $Camera2D/Control/MessagesOutput, $Camera2D/Control/Location, $Camera2D/Control/MessagesBG);

func _exit_tree() -> void:
	Instance = null;