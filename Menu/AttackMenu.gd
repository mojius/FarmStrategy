class_name AttackMenu extends PanelContainer

var _targets := []
var buttons: Array = []

@onready var vbox: VBoxContainer = $"MarginContainer/VBoxContainer"

signal attacking

func setup(targets) -> void:
	
	await ready
	
	_targets = targets
	
	for target in targets:
		var b: Button = Button.new()
		b.name = target.name
		b.text = target.name
		b.connect("pressed", Callable(attack).bind(target))
		vbox.add_child(b)
		b.grab_focus()
		
	
func attack(unit: Unit):
	attacking.emit(unit)

