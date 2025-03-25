extends Node

var terminal_input: LineEdit
var terminal_output: RichTextLabel
var messages_output: RichTextLabel
var messages_bg: ColorRect
var location_output: Label
var is_showing_dialogue = false
enum MessageTypes {NONE, SUCCESS, WARNING, ERROR, COMMAND}
enum Chars {NONE, DRONE, OP}
const TERMINAL_FAILURE_CHANCES = [0, 0, 0, 0.3, 0.6]
const ENDING_FAILURE_CHANCES = [0, 0.9, 0.8, 0.7, 0.6]
var COLOR_PER_TYPE = {
	MessageTypes.NONE: Color.WHITE,
	MessageTypes.SUCCESS: Color.GREEN,
	MessageTypes.WARNING: Color.YELLOW,
	MessageTypes.ERROR: Color.ORANGE_RED,
	MessageTypes.COMMAND: Color.AQUA
};
var COLOR_PER_CHAR = {
	Chars.NONE: Color.WHITE,
	Chars.DRONE: Color.ORANGE,
	Chars.OP: Color.HOT_PINK
};
var NAME_PER_CHAR = {
	Chars.NONE: "~",
	Chars.DRONE: "DRONE",
	Chars.OP: "OPERATOR"
};
const MAN_PAGES = {
	"goto": "SYNOPSIS\n\tgoto ROOM [-f]\n\nDESCRIPTION\n\tCommand drone (white dot) to go to ROOM.\n\tMovements will be added to a queue by default.\n\tForce movement with -f.",
	"door": "SYNOPSIS\n\tdoor DOOR1 [DOOR2 ...]\n\nDESCRIPTION\n\tOpen DOOR(S) remotely.\n\tDoors won't respond once destroyed.",
	"turret": "SYNOPSIS\n\tturret ROOM\n\nDESCRIPTION\n\tConnects to and toggles the turret (cyan dot) in ROOM.\n\tThe drone will be immovile during the connection process.\n\tConnection only has to be done once and takes 9s-15s.\n\tCancel the connection by typing 'turret cancel'.",
	"dest": "SYNOPSIS\n\tdest\n\nDESCRIPTION\n\tShows the room with access to the next zone.",
	"man": "SYNOPSIS\n\tman CMD\n\nDESCRIPTION\n\tShows this manual for CMD.",
	"clear": "SYNOPSIS\n\tclear\n\nDESCRIPTION\n\tClears the terminal output.",
	"scan": "SYNOPSIS\n\tscan\n\nDESCRIPTION\n\tToggles the drones scanner.\n\tONLY detects threats in neighbouring rooms.\n\tDetected threats will be shown in the map.\n\tCancels any drone movement.\n\tMoving the drone will disable the scanner.",
	"creatures": "SYNOPSIS\n\tcreatures [CREATURE]\n\nDESCRIPTION\n\tLists all creatures.\n\tIf CREATURE is provided, shows detailed information about CREATURE.",
	"list": "SYNOPSIS\n\tlist\n\nDESCRIPTION\n\tLists all available commands.",
	"help": "SYNOPSIS\n\thelp\n\nDESCRIPTION\n\tGives a brief introduction to the controls.",
}
const HELP_BASE = "Control the map camera with the arrow keys.\nZoom in and out with the '+' and '-' keys.\n\n'list' lists all available commands and 'man CMD' gives you a guide on CMD. For example: 'man goto'\nIf you need help reading command synopsis, type 'help 2'\n\nYou are STRONGLY ADVISED to read the manual for each command before continuing."
const HELP_2 = "SYNOPSIS\nThe format you should follow when typing a command.\nLowercase letters: Write them as is\nUppercase letters: Write the object of your commands\nSurrounded by []: Optional, but follow the same rules\n\nExample: The synopsis for the 'goto' command is 'goto ROOM [-f]'.\nThis means you should type 'goto' followed by a room code, and optionally '-f' to force the movement."
const CREATURE_PAGES = {
	"volo": "\n[center]VOLO[/center]\n[center][color=red]Scanner color: red[/color][/center]\nA small, hyperactive creature.\nAlways moves through any door in its current room when it's opened.\nWill destroy the drone if it's in the same room.\n", 
	"powa": "\n[center]POWA[/center]\n[center][color=cyan]Scanner color: cyan[/color][/center]\nA neutral, inmovile creature.\nCarries an electromagnetic field that disables any electronic devices in the room (not doors).\nDrone will take 4 seconds to reboot after any contact.\n",
	"mira": "\n[center]MIRA[/center]\n[center][color=green]Scanner color: green[/color][/center]\nA large, slow creature.\nAlways moves towards company issued drones.\nWill attack any door in its way and destroy the drone in contact.\n",
	"buro": "\n[center]BURO[/center]\n[center][color=orange]Scanner color: orange[/color][/center]\nA large, inmovile creature.\nMade of a compound that explodes when being nearby to company issued drones.\nAfter a wind up, it will explode and destroy the room, making it inaccessible.\nThe explosion also gets triggered by being killed.\n",
}
const ALL_COMMANDS = ["goto", "door", "turret", "dest", "man", "clear", "scan", "list", "creatures", "help"]
var VALID_COMMANDS = ["goto", "door", "dest", "clear", "turret", "man", "list", "help"]
var DRONE_COMMANDS = ["goto", "scan", "turret"]
var ongoing_dialogues = []
var dialogue_idx = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func _setup(p_terminal_input: LineEdit, p_terminal_output: RichTextLabel, p_messages_output: RichTextLabel, p_location_output: Label, p_messages_bg):
	terminal_input = p_terminal_input;
	terminal_output = p_terminal_output;
	messages_output = p_messages_output;
	location_output = p_location_output;
	messages_bg = p_messages_bg;
	terminal_input.connect("text_submitted", _on_text_submitted);

func cancel_all_dialogues():
	ongoing_dialogues.clear();

func dialogues_to_messages(dialogues: Array):
	var idx = dialogue_idx;
	dialogue_idx += 1;
	ongoing_dialogues.append(idx);
	is_showing_dialogue = true;
	for dialogue in dialogues:
		var delay = dialogue[0];
		var sender = NAME_PER_CHAR[dialogue[1]];
		var line = dialogue[2] + "\n";
		var text = "[%s] %s" % [sender, line];
		GameManager.create_safe_timer(delay, func():
			if (idx in ongoing_dialogues): messages_bg.color = Color.WHITE;
		);
		GameManager.create_safe_timer(delay + 0.5, func():
			messages_bg.color = Color.TRANSPARENT;
		);
		await get_tree().create_timer(delay).timeout;
		if (not idx in ongoing_dialogues):
			return;
		send_char_message(text, dialogue[1], true, true);
	is_showing_dialogue = false;
	ongoing_dialogues.erase(idx);
	
func update_location():
	location_output.text = "Current zone: z%s\nCurrent room: %s" % [GameManager.current_zone_idx, GameManager.current_room.name];

func send_char_message(message: String, chara: Chars = Chars.NONE, to_messages_output: bool = false, dismissable = false):
	MainGame.Instance.audio_message.play();
	send_message(message, COLOR_PER_CHAR[chara], to_messages_output, dismissable);

func send_type_message(message: String, message_type: MessageTypes = MessageTypes.NONE, to_messages_output: bool = false, dismissable = false):
	if (message_type == MessageTypes.SUCCESS):
		MainGame.Instance.audio_tercorrect.play();
	elif (message_type == MessageTypes.WARNING):
		MainGame.Instance.audio_terwarning.play();
	elif (message_type == MessageTypes.ERROR):
		MainGame.Instance.audio_tererror.play();
	send_message(message, COLOR_PER_TYPE[message_type], to_messages_output, dismissable);

func send_message(message: String, color: Color, to_messages_output: bool = false, dismissable = false):
	if (dismissable):
		color = Color(color.r, color.g, color.b, 0.75);
	var color_txt = color.to_html(true);
	var dest = messages_output if to_messages_output else terminal_output;

	var rd = randf();
	if (rd < TERMINAL_FAILURE_CHANCES[GameManager.current_zone_idx] or (GameManager.doing_ending and rd < ENDING_FAILURE_CHANCES[GameManager.current_zone_idx])):
		var err = randi_range(0, 2);
		if (err == 0):
			message = message.substr(0, 4 * len(message) / 5) + "0".repeat(len(message) / 5);
		elif (err == 1):
			message += " " + message.substr(1, len(message) / 3);
		elif (err == 2):
			message = message.replace(" ", ".");

	dest.text += "[color=%s]%s[/color]\n" % [color_txt, message];
	dest.scroll_to_line(dest.get_line_count());
	
	
func clear_terminal():
	terminal_output.text = "";

func clear_messages():
	messages_output.text = "";

func show_list():
	send_type_message("Available commands:");
	for cmd in VALID_COMMANDS:
		send_type_message("\t" + cmd);

func show_help():
	send_type_message(HELP_BASE);

func show_creatures(creature: String):
	if (creature == ""):
		send_type_message("Available creatures:");
		for c in CREATURE_PAGES.keys():
			send_type_message("\t" + c);
		send_type_message("Read about a specific creature by typing 'creatures CREATURE_NAME'.");
		return;
	if (creature not in CREATURE_PAGES.keys()):
		send_type_message("Creature not found.", MessageTypes.ERROR);
		return;
	send_type_message(CREATURE_PAGES[creature]);

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_accept") and terminal_input):
		terminal_input.grab_focus();
	elif (event.is_action_pressed("cancel_dialogues")):
		cancel_all_dialogues();

func add_command(cmd: String):
	VALID_COMMANDS.append(cmd);

func _on_text_submitted(text: String):
	text = text.strip_edges();
	if (text == ""):
		return;
	var argv = text.split(" ");
	var argc = len(argv);
	send_type_message("\n" + text, MessageTypes.COMMAND);
	terminal_input.text = "";

	if (argv[0] == "fzc" and argc >= 2):
		GameManager.force_change_zone(int(argv[1]));
		return;
	if (argv[0] == "diff" and argc >= 2):
		GameManager.set_difficulty(int(argv[1]));
		return;
	if (argv[0] == "mgw" and argc >= 2):
		GameManager.warp_to_room(argv[1]);
		return;

	if (argv[0] not in VALID_COMMANDS):
		Dialogues.send_terminal_response("invalid_command", []);
		return;

	if (GameManager.drone_instance.is_destroyed and argv[0] in DRONE_COMMANDS):
		send_type_message("Drone is destroyed.", MessageTypes.ERROR);
		return;
	if (GameManager.drone_instance.is_disabled and argv[0] in DRONE_COMMANDS):
		send_type_message("Drone is disabled.", MessageTypes.ERROR);
		return;
	if (GameManager.drone_instance.doing_ending and argv[0] in DRONE_COMMANDS):
		send_type_message("Drone is unresponsive.", MessageTypes.ERROR);
		return;

	if (argv[0] == "door" and argc >= 2):
		GameManager.current_zone.toggle_doors(argv.slice(1, argc));
	elif (argv[0] == "turret" and argc >= 2):
		if (argv[1] == "cancel"):
			GameManager.drone_instance.cancel_turret_connection();
		else:
			GameManager.current_zone.toggle_turret(argv[1]);
	elif (argv[0] == "dest"):
		GameManager.current_zone.print_dest();
	elif (argv[0] == "man" and argc >= 2 and argv[1] in VALID_COMMANDS):
		send_type_message(MAN_PAGES[argv[1]]);
	elif (argv[0] == "creatures"):
		show_creatures(argv[1] if argc >= 2 else "");
	elif (argv[0] == "help"):
		if (argc >= 2 and argv[1] == "2"):
			send_type_message(HELP_2);
		else:
			show_help();
	elif (argv[0] == "list"):
		show_list();
	elif (argv[0] == "clear"):
		clear_terminal();
	elif (argv[0] == "goto" and argc >= 2):
		var force = argc >= 3 && argv[2] == "-f";
		GameManager.drone_instance.start_moving_to(argv[1], force);
	elif (argv[0] == "scan"):
		GameManager.drone_instance.start_scan();
	else:
		send_type_message("Invalid command argument(s).", MessageTypes.ERROR);
