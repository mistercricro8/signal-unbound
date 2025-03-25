extends Node

var sfx_pct := 50.0

signal sfx_pct_changed

func set_sfx_pct(value: float) -> void:
	sfx_pct = value
	emit_signal("sfx_pct_changed", sfx_pct)