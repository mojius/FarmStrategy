class_name HealthPlant extends Plant


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await super._ready()
	unit_name = "Health Plant"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_grown():
	pass

func _on_harvested():
	pass
