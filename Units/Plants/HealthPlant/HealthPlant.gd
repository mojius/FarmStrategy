class_name HealthPlant extends Plant


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await super._ready()
	unit_name = "Health Plant"


func _on_grown():
	pass

func _on_harvested():
	pass
