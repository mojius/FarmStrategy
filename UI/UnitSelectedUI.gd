class_name UnitSelectedUI extends PanelContainer

@onready var move: Button = $MarginContainer/VBoxContainer/Move
@onready var attack: Button = $MarginContainer/VBoxContainer/Attack
@onready var wait: Button = $MarginContainer/VBoxContainer/Wait
@onready var items: Button = $MarginContainer/VBoxContainer/Items
@onready var harvest: Button = $MarginContainer/VBoxContainer/Harvest

signal delete

# Figure out how to pass null callable.
func setup(options: Dictionary):
	var move_func: Callable = make_callable(options, "move")
	var attack_func: Callable = make_callable(options, "attack")
	var harvest_func: Callable = make_callable(options, "harvest")
	var items_func: Callable = make_callable(options, "items")
	var wait_func: Callable = make_callable(options, "wait")
	
	move.text = "Move"
	attack.text = "Attack"
	wait.text = "Wait"
	harvest.text = "Harvest"
	items.text = "Items"
	bind_button(move, move_func)
	bind_button(attack, attack_func)
	bind_button(harvest, harvest_func)
	bind_button(wait, wait_func)
	bind_button(items, items_func)


# The way the menu appears and disappears needs tweaking.
func _on_pressed():
	queue_free()


func bind_button(button: Button, function: Callable, grab_focus: bool = false) -> void:
	if not function: return
	button.pressed.connect(function)
	button.show()
	if grab_focus: button.grab_focus()

func make_callable(options: Dictionary, strin: String):
	if options.has(strin):
		return Callable(options.get(strin))
	else:
		return Callable()
