extends Node

var currentScene: Node;
var transition_rect: ColorRect;
var gameScenes = {
	"main_menu": preload("res://Scenes/MainMenu.tscn"),
	"main_game": preload("res://Scenes/MainGame.tscn"),
};

func _setup(p_transition_rect: ColorRect):
	transition_rect = p_transition_rect;
	change_scene("main_menu");

func _ready() -> void:
	pass

func change_scene(to: String):
	_deferred_change_scene.call_deferred(to);
	
func _deferred_change_scene(to: String):
	transition_rect.visible = true;
	if (currentScene):
		Volo._clear_all_instances();
		currentScene.queue_free();
	currentScene = gameScenes[to].instantiate();
	get_tree().root.add_child(currentScene);
	await get_tree().create_timer(1).timeout;
	transition_rect.visible = false;
