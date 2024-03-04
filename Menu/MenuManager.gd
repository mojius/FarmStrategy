class_name MenuManager extends CanvasLayer
@export var _action_menu := preload("res://Menu/ActionMenu.tscn")

var menu: ActionMenu

func add_action_menu(attack: Callable, wait: Callable) -> void:
	menu = _action_menu.instantiate()
	menu.setup(attack, wait)
	add_child(menu)
	
func kill_action_menu() -> void:
	# Weird bug where you queue the menu tree twice, if you try to cancel out of the menu.
	if not (menu.is_queued_for_deletion()):
		remove_child(menu)
		menu.queue_free()
