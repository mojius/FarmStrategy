# Represents and manages the game board. Stores references to entities that are in each cell and
# tells whether cells are occupied or not.
# Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D

# Once again, we use our grid resource that we explicitly define in the class.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

@onready var _action_menu = preload("res://Menu/ActionMenu.tscn")
@onready var _attack_menu = preload("res://Menu/AttackMenu.tscn")
@onready var _ui_container: CanvasLayer = $UIContainer

var _active_menu: Control : 
	set(value):
		if not (_active_menu == null):
			var _old_menu = _active_menu
			_ui_container.remove_child(_old_menu)
		
		_active_menu = value
		if not (value == null):
			_ui_container.add_child(_active_menu)
			
			var enable_cursor = func():
				_cursor_enabled = true
			
			_cursor_enabled = false
			_active_menu.connect("tree_exiting", enable_cursor)

# We use a dictionary to keep track of the units that are on the board. Each key-value pair in the
# dictionary represents a unit. The key is the position in grid coordinates, while the value is a
# reference to the unit.
# Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}

# Phase animation.
@onready var _phase = preload("res://Juice/Phase.tscn")

@export_enum("Player", "Ally", "Enemy") var starting_faction: String = "Player"

# The player's active faction.
var _active_faction : String = "Player" :
	set(value):
		_cursor_enabled = false
		
		_active_faction = value
		
		await get_tree().create_timer(0.4).timeout
		
		_refresh_groups()
		var phase: Phase = _phase.instantiate()
		_ui_container.add_child(phase)
		await phase.done	
		
		if (value == "Player"):
			_cursor_enabled = true
		
		if not value == "Player":
			_cpu_turn(value)

# The board is going to move one unit at a time. When we select a unit, we will save it as our
# `_active_unit` and populate the walkable cells below. This allows us to clear the unit, the
# overlay, and the interactive path drawing later on when the player decides to deselect it.
var _active_unit: Unit

# This is kind of hacky, I know. I think we mostly need it for enemies.
var _active_path : PackedVector2Array

var _active_targets : Array = []

# This is an array of all the cells the `_active_unit` can move to. We will populate the array when
# selecting a unit and use it in the `_move_active_unit()` function below.
var _walkable_cells := []

# The cell we were at before deciding to try and move.
var _old_cell: Vector2 

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path_arrow: UnitPathArrow = $UnitPathArrow
@onready var _map: TileMap = $Map

# BD: This is a signal I'm gonna use for now to control the cursor from the gameboard.
signal cursor_enable(enabled: bool)

var _cursor_enabled: bool :
	set(value):
		_cursor_enabled = value
		cursor_enable.emit(value)

# At the start of the game, we initialize the game board. Look at the `_reinitialize()` function below.
# It populates our `_units` dictionary.
func _ready() -> void:
	randomize()
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
		unit.state_changed.connect(_on_unit_state_changed)

# Selects the unit in the `cell` if there's one there.
func player_select_unit(cell: Vector2) -> void:
	# Here's some optional defensive code: we return early from the function if the unit's not
	# registered in the `cell`.
	if (not _units.has(cell)):
		return
		
	if _units[cell].get_state() == "Exhausted" or not _units[cell].is_in_group("Player"):
		return

	# See the notes in previous commits for more info.
	_active_unit = _units[cell]
	_active_unit.is_selected = true
	
	_cursor_enabled = false
	
	_active_menu = _action_menu.instantiate()
	_active_menu.setup(_exhaust_active_unit, _show_movement_info, Callable())


# Shows the movement arrows and the yellow highlight, yadda yadda.
func _show_movement_info() -> void:
	_cursor_enabled = true
	_walkable_cells = _map.get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_unit_path_arrow.initialize(_walkable_cells)

# Deselects the active unit and gets rid of its... Shtuff. 
func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_active_unit = null
	_clear_movement_info()
	
	# Come back to this.
	_active_targets.clear()
	
# Clears the movement-related stuff to the active unit. For player units.
func _clear_movement_info() -> void:
	_unit_overlay.clear()
	_unit_path_arrow.stop()
	_walkable_cells.clear()

	
# Teleports a unit instantly to a position. Used for undoing movement for now.
func _teleport_active_unit(new_cell: Vector2) -> void:
	if is_occupied(new_cell):
		return
	
	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	
	_active_unit.position = grid.calculate_map_position(new_cell)
	_active_unit.cell = new_cell


# Updates the _units dictionary with the target position for the unit and asks the _active_unit to
# walk to it.
func _move_active_unit(new_cell: Vector2, is_player: bool = true) -> void:
	if is_occupied(new_cell) or not new_cell in _walkable_cells:
		return

	_old_cell = _active_unit.cell
	
	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	# Finally, we clear the active unit, we won't need it after this.
	_clear_movement_info()

	_cursor_enabled = false
	_units[new_cell].walk_along(_active_path)
	await _units[new_cell].walk_finished
	
	_units[new_cell].set_state("Moved")
	
	if not is_player: return
	
	_find_targets_in_range()
	_add_post_move_menu()

# Updates the interactive path's drawing if there's an active and selected unit.
func _on_cursor_moved(new_cell: Vector2) -> void:
	# When the cursor moves, and we already have an active unit selected, we want to update the
	# interactive path drawing.

	if _active_unit and _active_unit.is_selected and _cursor_enabled:
		_unit_path_arrow.draw(_active_unit.cell, new_cell)

# Selects or moves a unit based on where the cursor is.
func _on_cursor_accept_pressed(cell: Vector2) -> void:
	# The cursor's "accept_pressed" means that the player wants to interact with a cell. Depending
	# on the board's current state, this interaction means either that we want to select a unit or
	# that we want to give it a move order.
	if not _active_unit:
		player_select_unit(cell)
	elif _active_unit.is_selected:
		_active_path = _unit_path_arrow.current_path
		_move_active_unit(cell)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _active_unit:
			if _active_unit.get_state() == "Moved" and (_old_cell):
				_teleport_active_unit(_old_cell)
				
			_deselect_active_unit()
			_cursor_enabled = true
			_active_menu = null
			
			# Undoes the finalization of the movement

# Sets the active unit to exhausted and disables it. Probably something we can get rid of later.
func _exhaust_active_unit() -> void:
	if _active_unit:
		_cursor_enabled = true
		_active_unit.set_state("Exhausted")
		_deselect_active_unit()

func _on_unit_state_changed(unit: Unit) -> void:
	var state = unit.get_state()
	if (state == "Exhausted"):
		_check_should_turn_end()
		pass
	elif (state == "Moved"):
		pass
	
func _check_should_turn_end():
	var faction_units := get_tree().get_nodes_in_group(_active_faction)
	for unit: Unit in faction_units:
		if not unit.get_state() == "Exhausted":
			return

	_active_faction = "Enemy" if _active_faction == "Player" else "Player"
	

func _refresh_group(faction: String) -> void:
	# TODO: Validate the states later, or find a better way to do it.
	
	var faction_units := get_tree().get_nodes_in_group(faction)
	for unit: Unit in faction_units:
		unit.set_state("Idle")

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
		if path.is_empty() or path.size() == 9999:
				_deselect_active_unit()
				continue
		
		# Shorten the path so you don't go right ONTO your target. 
		# Later we scale this by the attack range of the enemy.
		path.remove_at(path.size() - 1)
		
		if (path.size() <= 1):		
			_find_targets_in_range()
			if (_active_targets.size() > 0):
				attack(_active_targets.pick_random())
				continue
		
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
		_move_active_unit(target_cell, false)
		await unit.walk_finished 
		
		_find_targets_in_range()
		if (_active_targets.size() > 0):
			attack(_active_targets.pick_random())
	
	_active_faction = target_faction
	
# Finds all targets in range.
func _find_targets_in_range():
	
	# Putting this duplicate code here is hacky... Man whatever.
	const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

	for direction in DIRECTIONS:
		var coordinates: Vector2 = _active_unit.cell + direction
		
		if _units.has(coordinates) and _units.get(coordinates).get_faction() == _active_unit.get_enemy_faction() and _units.get(coordinates) not in _active_targets:
			_active_targets.append(_units[coordinates])

# Adds a menu after moving. Let's make this a builder later or something. This is a mess.
func _add_post_move_menu():
	_active_menu = _action_menu.instantiate()
	
	if (_active_targets.size() > 0):
		_active_menu.setup(_exhaust_active_unit, Callable(), player_try_attack)
	else:
		_active_menu.setup(_exhaust_active_unit)
	
func player_try_attack():
	if (_active_targets.size() <= 0):
		return
		
	_active_menu = _attack_menu.instantiate()
	_active_menu.setup(attack, _active_targets)

func attack(unit: Unit):
	unit.queue_free()
	SoundNode.Hit_Sound()
	_units.erase(unit.cell)
	_exhaust_active_unit()

