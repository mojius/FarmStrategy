class_name InventoryUI extends Control

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer
@onready var item_button = preload("res://UI/Inventory/ItemButton.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup(inventory: Array[Item], unit: Unit) -> void:
	for item in inventory:
		var b: Button = item_button.instantiate()
		b.setup(item)
		list.add_child(b)
		var use_func = Callable(item, "use")
		print(use_func)
		print(unit)
		var bound = use_func.bind(unit)
		b.pressed.connect(bound)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_item():
	pass
	
func remove_item():
	pass
	
