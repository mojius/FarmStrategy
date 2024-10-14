class_name Plant extends GridActor

@export var stages = 5
var _stage: int = 0: 
	set(value):
		_stage = value
		$PathFollow2D/Sprite.frame = _stage
		print("Frame is ", $PathFollow2D/Sprite.frame)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_grown():
	pass

func _on_harvested():
	pass

func grow():
	_stage = _stage + 1
	if (_stage == stages):
		_on_grown()
	
