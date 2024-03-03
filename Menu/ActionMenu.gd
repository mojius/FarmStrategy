class_name ActionMenu extends PanelContainer

@onready var move: Button = $MarginContainer/VBoxContainer/Move
@onready var attack: Button = $MarginContainer/VBoxContainer/Attack
@onready var items: Button = $MarginContainer/VBoxContainer/Items
@onready var wait: Button = $MarginContainer/VBoxContainer/Wait

var _unit: Unit

func setup(move_func: Callable, wait_func: Callable):
	await self.ready
	move.pressed.connect(move_func)
	wait.pressed.connect(wait_func)
	move.grab_focus()

func _on_move_pressed():
	queue_free()
	
func _on_wait_pressed():
	queue_free()
