class_name ActionMenu extends PanelContainer

@onready var move: Button = $MarginContainer/VBoxContainer/Move
@onready var attack: Button = $MarginContainer/VBoxContainer/Attack
@onready var items: Button = $MarginContainer/VBoxContainer/Items
@onready var wait: Button = $MarginContainer/VBoxContainer/Wait

signal delete

# Figure out how to pass null callable.
func setup(wait_func: Callable, move_func: Callable = Callable(), attack_func: Callable = Callable()):

	if (move_func):
		move.pressed.connect(move_func)
		move.show()
		move.grab_focus()
	if (wait_func):
		wait.pressed.connect(wait_func)
		wait.show()
	if (attack_func):
		attack.pressed.connect(attack_func)
		attack.show()

# The way the menu appears and disappears needs tweaking.
func _on_move_pressed():
	queue_free()
	
func _on_wait_pressed():
	queue_free()

func _on_attack_pressed():
	queue_free()
