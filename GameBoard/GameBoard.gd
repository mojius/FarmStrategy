# Represents and manages the game board. Stores references to entities that are in each cell and
# tells whether cells are occupied or not.
# Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D

# Once again, we use our grid resource that we explicitly define in the class.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

# We use a dictionary to keep track of the units that are on the board. Each key-value pair in the
# dictionary represents a unit. The key is the position in grid coordinates, while the value is a
# reference to the unit.
# Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}

@onready var _phase = preload("res://Juice/Phase.tscn")

@export_enum("Player", "Ally", "Enemy") var starting_faction: String = "Player"

var _active_faction : String = "Player" :
	set(value):
		
		_refresh_groups()
		var phase: Phase = _phase.instantiate()
		_menu_manager.add_child(phase)
		await phase.done
		
		_active_faction = value
		if (value != "Player"):
			_state = GameState.DISABLED
		elif (value == "Player"):
			_state = GameState.FREE
		
		if not value == "Player":
			_cpu_turn(value)

var _active_path : PackedVector2Array

# Ben D: Hopefully this streamlines things a bit.
# Possibly migrate this to cursor?
enum GameState 
{
	FREE,
	DISABLED,
	TRY_MOVE,
	TRY_ATTACK
}

var _state := GameState.FREE :
	set(value):
		_state = value
		if (value == GameState.DISABLED):
			cursor_enable.emit(false)
		elif (value == GameState.FREE or
			value == GameState.TRY_MOVE or
			value == GameState.TRY_ATTACK):
			cursor_enable.emit(true)

# The board is going to move one unit at a time. When we select a unit, we will save it as our
# `_active_unit` and populate the walkable cells below. This allows us to clear the unit, the
# overlay, and the interactive path drawing later on when the player decides to deselect it.
var _active_unit: Unit
# This is an array of all the cells the `_active_unit` can move to. We will populate the array when
# selecting a unit and use it in the `_move_active_unit()` function below.
var _walkable_cells := []

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path_arrow: UnitPathArrow = $UnitPathArrow
@onready var _map: TileMap = $Map
@onready var _menu_manager: CanvasLayer = $MenuManager

# Ben D: This is a signal I'm gonna use for now to control the cursor from the gameboard.
signal cursor_enable(enabled: bool)

# At the start of the game, we initialize the game board. Look at the `_reinitialize()` function below.
# It populates our `_units` dictionary.
func _ready() -> void:
	_reinitialize()

# Returns `true` if the cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	return true if _units.has(cell) else false
	
# Clears, and refills the `_units` dictionary with game objects that are on the board.
func _reinitialize() -> void:
	_active_faction = starting_faction
	_units.clear()

	# Loop over the nodes in the unit group.
	for member in get_tree().get_nodes_in_group("Unit"):
		var unit := member as Unit
		if not unit:
			continue
		
		# Using a dictionary of grid coordinates here.
		_units[unit.cell] = unit
		unit.turn_exhausted.connect(_on_unit_exhausted)

# Selects the unit in the `cell` if there's one there.
func _select_unit(cell: Vector2) -> void:
	# Here's some optional defensive code: we return early from the function if the unit's not
	# registered in the `cell`.
	if not _units.has(cell):
		return

	if _units[cell].is_exhausted():
		return
		
	if not _units[cell].is_in_group("Player"):
		return
	# See the notes in previous commits for more info.
	_active_unit = _units[cell]
	_active_unit.is_selected = true
	
	_state = GameState.DISABLED
	_menu_manager.add_action_menu(_try_move_unit, _exhaust)
	
func _try_move_unit() -> void:
	_state = GameState.TRY_MOVE
	_walkable_cells = _map.get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_unit_path_arrow.initialize(_walkable_cells)


func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path_arrow.stop()
	_active_unit = null
	_walkable_cells.clear()	

# Updates the _units dictionary with the target position for the unit and asks the _active_unit to
# walk to it.
func _move_active_unit(new_cell: Vector2) -> void:
	if is_occupied(new_cell) or not new_cell in _walkable_cells:
		return

	# When moving a unit, we need to update our `_units` dictionary. We instantly save it in the
	# target cell even if the unit itself will take time to walk there.
	# While it's walking, the player won't be able to issue new commands.
	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	# Finally, we clear the active unit, we won't need it after this.
	_deselect_active_unit()

	_units[new_cell].walk_along(_active_path)
	await _units[new_cell].walk_finished
	
	# Now that the unit is done moving, set it as exhausted.
	_units[new_cell].set_exhausted(true)
	
	# Finally, we clear the `_active_unit`, which also clears the `_walkable_cells` array.


# Updates the interactive path's drawing if there's an active and selected unit.
func _on_cursor_moved(new_cell: Vector2) -> void:
	# When the cursor moves, and we already have an active unit selected, we want to update the
	# interactive path drawing.

	if _active_unit and _active_unit.is_selected and _state == GameState.TRY_MOVE:
		_unit_path_arrow.draw(_active_unit.cell, new_cell)

# Selects or moves a unit based on where the cursor is.
func _on_cursor_accept_pressed(cell: Vector2) -> void:
	# The cursor's "accept_pressed" means that the player wants to interact with a cell. Depending
	# on the board's current state, this interaction means either that we want to select a unit all
	# that we want to give it a move order.
	if not _active_unit:
		_select_unit(cell)
	elif _active_unit.is_selected:
		_active_path = _unit_path_arrow.current_path
		_move_active_unit(cell)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _active_unit:
			_deselect_active_unit()
			_state = GameState.FREE
			_menu_manager.kill_action_menu()
		

# Sets the active unit to exhausted and disables it. Probably something we can get rid of later.
func _exhaust() -> void:
	if _active_unit:
		_active_unit.set_exhausted(true)
		_deselect_active_unit()
		_state = GameState.FREE

func _on_unit_exhausted() -> void:
	_check_should_end_turn()
	
func _check_should_end_turn():
	var faction_units := get_tree().get_nodes_in_group(_active_faction)
	for unit: Unit in faction_units:
		if not unit.is_exhausted():
			return

	if _active_faction == "Player":
		_active_faction = "Enemy"
		return
	elif _active_faction == "Enemy":
		_active_faction = "Player"	
		return

func _refresh_group(faction: String) -> void:
	# TODO: Validate these later, or find a better way to do it.
	
	var faction_units := get_tree().get_nodes_in_group(faction)
	for unit: Unit in faction_units:
		unit.set_exhausted(false)

func _refresh_groups() -> void:
	_refresh_group("Player")
	_refresh_group("Ally")
	_refresh_group("Enemy")

# Have the CPU take a turn. This AI is very rough and simple right now.
func _cpu_turn(faction: String) -> void:
	
	# Change this later.
	var target_faction := "Player"
	var target_faction_units := get_tree().get_nodes_in_group(target_faction)
	
	var faction_units := get_tree().get_nodes_in_group(faction)
	for unit: Unit in faction_units:
		
		_active_unit = unit
		_active_unit.is_selected = true
	
		var closest_cell: Vector2 = Vector2(999,999)

		# First get the walkable points, then init a path.
		_walkable_cells = _map.get_walkable_cells(unit)
		var pathfinder = PathFinder.new(grid, _walkable_cells)
		var path := PackedVector2Array()
		path.resize(9999)
		
		# Find the closest unit of the target faction units.
		for enemy: Unit in target_faction_units:
			var new_path := pathfinder.calculate_point_path(unit.cell, enemy.cell)
			
			if (not new_path.is_empty() and new_path.size() < path.size()):
				path = new_path

		# If we can't immediately attack an enemy in range or we're right next to them,
		if path.is_empty() or path.size() == 9999 or path.size() <= 1:
				_deselect_active_unit()
				continue
		
		# Shorten the path so you don't go right ONTO your target. 
		# Later we scale this by the attack range of the enemy.
		path.remove_at(path.size() - 1)
		
		var target_cell: Vector2 = path[path.size() - 1]
		
		# If we can't immediately attack an enemy in range or we're right next to them,
		if path.is_empty() or path.size() == 9999 or path.size() <= 1:
				_deselect_active_unit()
				continue
				
		if is_occupied(target_cell) or not target_cell in _walkable_cells:
				_deselect_active_unit()
				continue
						
		_active_path = path
		# Move the enemy to the last element in the path.
		_move_active_unit(target_cell)
		await unit.walk_finished 
	
	_active_faction = target_faction

