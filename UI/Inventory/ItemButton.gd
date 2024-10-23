class_name ItemButton extends Button

var _item: Item

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup(item: Item) -> void:
	_item = item
	text = _item.item_name
	icon = item.icon

func get_item() -> Item:
	return _item

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
