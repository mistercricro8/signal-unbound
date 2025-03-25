extends AudioStreamPlayer2D
class_name AudioPlayer

@export var inner_pct := 1.0

func _ready() -> void:
	Globals.connect("sfx_pct_changed", _on_volume_changed)
	GameManager.create_safe_timer(0.01, func():
		_on_volume_changed(Globals.sfx_pct)
	)

func _on_volume_changed(pct: float) -> void:
	pct *= inner_pct
	volume_db = pct_to_db(pct)

func _change_inner_pct(pct: float) -> void:
	inner_pct = pct
	_on_volume_changed(Globals.sfx_pct)

func pct_to_db(pct: float) -> float:
	return 20 * log(pct / 100) / log(10)
