extends Node2D

func _ready() -> void:
	SceneController._setup($Camera2D/CanvasLayer/Transition);
