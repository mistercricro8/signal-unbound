extends Control

@onready var slider := $VBoxContainer/HBoxContainer2/SFXSlider

signal _value_changed
signal _drag_ended

func _ready() -> void:
	slider.value = Globals.sfx_pct;

func _on_sfx_slider_value_changed(value: float) -> void:
	emit_signal("_value_changed", value);

func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	emit_signal("_drag_ended");
