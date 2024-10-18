# Represents and manages the game board. Stores references to entities that are in each cell and
# tells whether cells are occupied or not.
# units can only move around the grid one at a time.
class_name GameBoard extends Node2D

# Once again, we use our grid resource that we explicitly define in the class.
@export var grid: Grid = preload("res://GameBoard/Grid.tres")

@onready var _faction_manager : FactionManager = $FactionManager
@onready var _ui_manager: UIManager = $UIManager
@onready var _highlight: HighlightInfoUI = $UIManager/HighlightInfoUI
@onready var _units: UnitManager = $Map/UnitManager
@onready var _plants: PlantManager = $Map/PlantManager
@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path_arrow: UnitPathArrow = $UnitPathArrow
@onready var _map: Map = $Map

# 4 directions. For flood fill and other map-related stuff.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var ui_functions: Dictionary = {
	"attack" : Callable(self, "_player_try_attack"),
	"harvest": Callable(self, "_player_try_harvest"),
	"plant": Callable(self, "_player_try_plant"),
	"wait": Callable(self, "_exhaust_active_unit"),
	"move": Callable(self, "_show_movement_info")
	}
	
@export_enum("Player", "Ally", "Enemy") var starting_faction: String = "Player"

var num_plants: int = 0

# The board is going to move one unit at a time. When we select a unit, we will save it as our
# `_active_unit` and populate the walkable cells below. This allows us to clear the unit, the
# overlay, and the interactive path drawing later on when the player decides to deselect it.
var _active_unit: Unit

# This is kind of hacky, I know. I think we mostly need it for enemies.
var _active_path : PackedVector2Array

# This is an array of all the cells the `_active_unit` can move to. We will populate the array when
# selecting a unit and use it in the `_move_active_unit()` function below.
var _walkable_cells := []

# The cell we were at before deciding to try and move.
var _old_cell: Vector2 

# BD: This is a signal I'm gonna use for now to control the cursor from the gameboard.
signal cursor_enable(enabled: bool)

var _cursor_enabled: bool :
	set(value):
		_cursor_enabled = value
		cursor_enable.emit(value)
		_highlight.hide()

# At the start of the game, we initialize the game board. Look at the `_reinitialize()` function below.
# It populates our `_units` dictionary.
func _ready() -> void:
	randomize()
	_faction_manager.set_active_faction(starting_faction)
	_units.connect("check_should_turn_end", _faction_manager._check_should_turn_end)

# Selects the unit in the `cell` if there's one there.
func player_select_unit(cell: Vector2) -> void:
	# Here's some optional defensive code: we return early from the function if the unit's not
	# registered in the `cell`.
	if (not _units.has_unit_at(cell)):
		return
		
	if _units.get_unit_at(cell).get_state() == "Exhausted" or not _units.get_unit_at(cell).is_in_group("Player"):
		return

	# See the notes in previous commits for more info.
	_active_unit = _units.get_unit_at(cell)
	_active_unit.is_selected = true
	
	_cursor_enabled = false
	
	var targets = _units._find_units_in_range(_active_unit)
	_ui_manager.add_unit_selected_ui(targets.size(), ui_functions)

# Shows the movement arrows and the yellow highlight, yadda yadda.
func _show_movement_info() -> void:
	_cursor_enabled = true
	_walkable_cells = _map.get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_unit_path_arrow.initialize(_map)

# Deselects the active unit and gets rid of its... Shtuff. 
func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_active_unit = null
	_clear_movement_info()

	
# Clears the movement-related stuff to the active unit. For player units.
func _clear_movement_info() -> void:
	_unit_overlay.clear()
	_unit_path_arrow.stop()
	_walkable_cells.clear()

	
# Teleports a unit instantly to a position. Used for undoing movement for now.
func _teleport_active_unit(new_cell: Vector2) -> void:
	if _map.is_occupied(new_cell):
		return
	
	_units.erase_unit_at(_active_unit.cell)
	_units.set_unit_at(_active_unit, new_cell)
	
	_active_unit.position = grid.calculate_map_position(new_cell)
	_active_unit.cell = new_cell


# Updates the _units dictionary with the target position for the unit and asks the _active_unit to
# walk to it.
func _move_active_unit(new_cell: Vector2, is_player: bool = true) -> void:
	if _map.is_occupied(new_cell):
		return

	_old_cell = _active_unit.cell
	
	_units.erase_unit_at(_active_unit.cell)
	_units.set_unit_at(_active_unit, new_cell)
	# Finally, we clear the active unit, we won't need it after this.
	_clear_movement_info()

	_cursor_enabled = false
	_units.get_unit_at(new_cell).walk_along(_active_path)
	await _units.get_unit_at(new_cell).walk_finished
	
	_units.get_unit_at(new_cell).set_state("Moved")
	
	if not is_player: return
	
	var targets = _units._find_units_in_range(_active_unit)
	_ui_manager.add_post_move_ui(targets.size(), ui_functions)

# Updates the interactive path's drawing if there's an active and selected unit.
func _on_cursor_moved(new_cell: Vector2) -> void:
	var unit = _units.get_unit_at(new_cell)
	_highlight.cursor_moved(new_cell, unit)
	
	# When the cursor moves, and we already have an active unit selected, we want to update the
	# interactive path drawing.
	if _active_unit and _active_unit.is_selected and _cursor_enabled:
		_unit_path_arrow.draw(_active_unit, new_cell)
		return

# Selects or moves a unit based on where the cursor is.
func _on_cursor_accept_pressed(cell: Vector2) -> void:
	# The cursor's "accept_pressed" means that the player wants to interact with a cell. Depending
	# on the board's current state, this interaction means either that we want to select a unit or
	# that we want to give it a move order.
	if not _active_unit:
		player_select_unit(cell)
	elif _active_unit.is_selected and not _units.has_unit_at(cell) and not _map.get_impassable_at_tile(cell):
		if cell in _map.breadth_first_search(_active_unit.cell, _active_unit.move_range):
			_active_path = _unit_path_arrow.current_path
			_move_active_unit(cell)

# Checks for unhandled input, mainly UI cancel actions. Messy.
func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_cancel"):
		if _active_unit:
			if _active_unit.get_state() == "Moved" and (_old_cell):
				_teleport_active_unit(_old_cell)
				
			if _active_unit.get_state() != "Attacking" and _active_unit.get_state() != "Dead":
				_deselect_active_unit()
				_cursor_enabled = true
				_ui_manager.clear_active_ui()
			
			# Undoes the finalization of the movement

# Sets the active unit to exhausted and disables it.
func _exhaust_active_unit() -> void:
	if _active_unit:
		_cursor_enabled = true
		_active_unit.set_state("Exhausted")
		_deselect_active_unit()



# Have the CPU take a turn. This AI is very rough and simple right now.
func _cpu_turn(faction: String) -> void:
	
	# Change this later.
	var target_faction = _faction_manager._get_opposing_faction(faction)
	
	var faction_units := get_tree().get_nodes_in_group(faction)
	for unit: Unit in faction_units:
		await _cpu_think(unit)
	
	_faction_manager.set_active_faction(target_faction)
	

func _cpu_think(unit: Unit):
	_active_unit = unit
	_active_unit.is_selected = true
	const INVALID_PATH = 9999
	
	var target_faction = _faction_manager._get_opposing_faction(_active_unit._faction)
	var target_faction_units := get_tree().get_nodes_in_group(target_faction)
	
	if (await _try_attack_in_range()):
			return
	var path := []
	path.resize(INVALID_PATH)
	
	for enemy: Unit in target_faction_units:
		var pInfo: PathInfo = PathInfo.new(_active_unit.cell, enemy.cell, _active_unit.move_range)
		pInfo.is_player = false
		
		var new_path : Array = _map.calculate_path(pInfo)
		if (not new_path.is_empty() and new_path.size() < path.size()):
			path = new_path

	# If we can't immediately attack an enemy in range or we're right next to them,
	if path.is_empty() or path.size() == INVALID_PATH:
			_deselect_active_unit()
			return
	
	_active_path = path
	
	# Move the enemy to the last element in the path.
	_move_active_unit(path[path.size() - 1], false)
	await unit.walk_finished 
	
	if (await _try_attack_in_range()):
		return
	
	if (not _active_unit == null):
		_deselect_active_unit()

func _try_attack_in_range() -> bool:
	var targets: Array = _units._find_units_in_range(_active_unit)
	if (targets.size() > 0):
		await attack(targets.pick_random())
		return true
	return false

# Player: See if there are targets near you, so that you may attack.
func _player_try_attack():
	var targets = _units._find_units_in_range(_active_unit)
	if (targets.size() <= 0):
		return
	
	_ui_manager.add_attack_ui(attack, targets)

func _player_try_harvest():
	var target_plants: Array = _plants._find_plants_in_range(_active_unit)
	if (target_plants.size() <= 0):
		return
	
	_ui_manager.add_harvest_ui(harvest, target_plants)

func attack(unit: Unit):
	_active_unit.set_state("Attacking")
	_cursor_enabled = false
	var combat_object: CombatObject = load("res://Combat/CombatObject.tscn").instantiate()
	_ui_manager.set_active_ui(combat_object) 
	combat_object.setup(_active_unit, unit)
	
	await combat_object.attack_finished
	_ui_manager.clear_active_ui()
	
	_exhaust_active_unit()

func harvest(plant: Plant):
	_plants.erase_plant_at(plant.cell)
	num_plants = num_plants+1
	_exhaust_active_unit()
