extends Node2D

@onready var start_color := $Camera2D/CanvasLayer/MainMenu/TextureRect2/VBoxContainer/Start/Color
@onready var credits_color := $Camera2D/CanvasLayer/MainMenu/TextureRect2/VBoxContainer/Credits/Color
@onready var credits := $Camera2D/CanvasLayer/MainMenu/Credits
@onready var thanks := $Camera2D/CanvasLayer/MainMenu/TextureRect2/Thanks
@onready var audio_select := $AudioSelect
@onready var audio_start := $AudioStart
var currently_highlight: ColorRect
var normal_color := Color.WHITE
var highlight_color := Color.html("#bcbcbc")

func _ready() -> void:
	if (GameManager.game_completed):
		thanks.visible = true;

func _on_start_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
			audio_start.play();
			SceneController.change_scene("main_game");

func _on_credits_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
			audio_select.play();
			credits.visible = true;

func _on_close_credits_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
			audio_select.play();
			credits.visible = false;

func _on_start_mouse_entered() -> void:
	if (currently_highlight):
		currently_highlight.color = normal_color;
	currently_highlight = start_color;
	currently_highlight.color = highlight_color;
	
func _on_credits_mouse_entered() -> void:
	if (currently_highlight):
		currently_highlight.color = normal_color;
	currently_highlight = credits_color;
	currently_highlight.color = highlight_color;

func _on_audio__value_changed(value: float) -> void:
	Globals.set_sfx_pct(value);

func _on_audio__drag_ended() -> void:
	if (audio_select):
		audio_select.play();
