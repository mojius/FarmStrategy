class_name MenuManager extends CanvasLayer
@export var _action_menu := preload("res://Menu/ActionMenu.tscn")

func add_action_menu(attack: Callable, wait: Callable) -> void:
	var menu = _action_menu.instantiate()
	menu.setup(attack, wait)
	add_child(menu)
	
func kill_action_menu() -> void:
	if (get_child(0)):
		get_child(0).queue_free()
