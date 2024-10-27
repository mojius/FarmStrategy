class_name UIManager extends CanvasLayer


@onready var _unit_selected_ui = preload("res://UI/UnitSelectedUI.tscn")
@onready var _attack_ui = preload("res://UI/AttackUI.tscn")
@onready var _harvest_ui = preload("res://UI/HarvestUI.tscn")
@onready var _inventory_ui = preload("res://UI/InventoryUI.tscn")
@onready var _plant_ui = preload("res://UI/PlantUI.tscn")
@onready var combat_object = preload("res://Combat/CombatObject.tscn")

signal cursor_enable(enabled: bool)

var _active_ui

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

		
func _set_active_ui(ui: Control):
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
	_set_active_ui(_unit_selected_ui.instantiate())
	
	if (num_targets < 1):
		_opt.erase("attack")
	_active_ui.setup(_opt)

# Adds the attack UI for selecting a target to attack.
func add_attack_ui(_attack: Callable, _active_targets: Array):
	_set_active_ui(_attack_ui.instantiate())
	_active_ui.setup(_attack, _active_targets)
	
func add_plant_ui(plant_func: Callable, _seed: Seed, active_spots: Array):
	_set_active_ui(_plant_ui.instantiate())
	_active_ui.setup(plant_func, _seed, active_spots)
	
func add_harvest_ui(_harvest: Callable, target_plants: Array):
	_set_active_ui(_harvest_ui.instantiate())
	_active_ui.setup(_harvest, target_plants)

func run_combat_ui(attacker: Unit, target: Unit):
	var combat: CombatObject = combat_object.instantiate()
	_set_active_ui(combat)
	combat.setup(attacker, target)
	await combat.attack_finished

func add_inventory_ui(inventory: Array[Item], unit: Unit):
	_set_active_ui(_inventory_ui.instantiate())
	_active_ui.setup(inventory, unit)

func clear_active_ui() -> void:
	_set_active_ui(null)

func add_unit_selected_ui(moved: bool, seeking_targets: bool, seeking_plants: bool, empty_inventory: bool, options: Dictionary):
	var _opt: Dictionary = options.duplicate()

	if (moved):
		_opt.erase("move")
	if (not seeking_targets):
		_opt.erase("attack")
	if (not seeking_plants):
		_opt.erase("harvest")
	if (empty_inventory):
		_opt.erase("items")
		
	_set_active_ui(_unit_selected_ui.instantiate())
	_active_ui.setup(_opt)

func _on_next_phase(phase: Phase):
	add_child(phase)
