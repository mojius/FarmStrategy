class_name UIManager extends CanvasLayer


@onready var _unit_selected_ui = preload("res://UI/UnitSelectedUI.tscn")
@onready var _attack_ui = preload("res://UI/AttackUI.tscn")
signal cursor_enable(enabled: bool)

var _active_ui

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

		
func set_active_ui(ui: Control):
	if not (_active_ui == null):
		var _old_ui = _active_ui
		remove_child(_old_ui)
	
	_active_ui = ui
	if not (ui == null):
		add_child(_active_ui)

		cursor_enable.emit(false)

# Adds a menu after moving. Let's make this a builder later or something. This is a mess.
func add_post_move_ui(num_targets: int, options: Dictionary):
	var _opt: Dictionary = options.duplicate()
	set_active_ui(_unit_selected_ui.instantiate())
	
	if (num_targets < 1):
		_opt.erase("attack")
	_active_ui.setup(_opt)

# Adds the attack UI for selecting a target to attack.
func add_attack_ui(_attack: Callable, _active_targets: Array):
	set_active_ui(_attack_ui.instantiate())
	_active_ui.setup(_attack, _active_targets)

func clear_active_ui() -> void:
	set_active_ui(null)

	
func add_unit_selected_ui(num_targets: int, options: Dictionary):
	var _opt: Dictionary = options.duplicate()
	if (num_targets < 1):
		_opt.erase("attack")
	set_active_ui(_unit_selected_ui.instantiate())
	_active_ui.setup(_opt)
