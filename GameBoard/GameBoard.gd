# Represents and manages the game board. Stores references to entities that are in each cell and
# tells whether cells are occupied or not.
# Units can only move around the grid one at a time.
class_name GameBoard extends Node2D

# Once again, we use our grid resource that we explicitly define in the class.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

@onready var _action_ui = preload("res://UI/ActionUI.tscn")
@onready var _attack_ui = preload("res://UI/AttackUI.tscn")
@onready var _ui_container: CanvasLayer = $UIContainer
@onready var _cursor: Cursor = $Cursor
@onready var _highlight: HighlightInfoUI = $UIContainer/HighlightInfoUI

# 4 directions. For flood fill and other map-related stuff.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

# The currently active UI element. Highlight UIs are not part of this.
var _active_ui: Control : 
	set(value):
		if not (_active_ui == null):
			var _old_ui = _active_ui
			_ui_container.remove_child(_old_ui)
		
		_active_ui = value
		if not (value == null):
			_ui_container.add_child(_active_ui)

			_cursor_enabled = false


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
		
		_refresh_factions()
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

# An array of targets in range of the active unit.
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
		_highlight.hide()

# At the start of the game, we initialize the game board. Look at the `_reinitialize()` function below.
# It populates our `_units` dictionary.
func _ready() -> void:
	TranslationServer.set_locale("en")
	randomize()
	_reinitialize()

# Returns `true` if the cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	
	return true if _units.has(cell) and _units[cell].get_faction() != "Player" and _units[cell].get_faction() == "Enemy" else false
	
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
	
	_find_targets_in_range()
	var attackable: Callable = Callable()
	
	if (_active_targets.size() > 0):
		attackable = _add_attack_ui
	
	_active_ui = _action_ui.instantiate()
	_active_ui.setup(_exhaust_active_unit, _show_movement_info, attackable)


# Shows the movement arrows and the yellow highlight, yadda yadda.
func _show_movement_info() -> void:
	_cursor_enabled = true
	_walkable_cells = get_walkable_cells(_active_unit)
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
	_add_post_move_ui()

# Updates the interactive path's drawing if there's an active and selected unit.
func _on_cursor_moved(new_cell: Vector2) -> void:
	
	
	if _units.has(new_cell):
		_highlight.refresh(_units[new_cell])
		_highlight.show()
	else: _highlight.hide()
		
	var center = get_viewport_rect().size / 2
	var pixel_pos = grid.calculate_map_position(new_cell)
	
	if pixel_pos.x < center.x and pixel_pos.y < center.y:
		_highlight.set_bottom_left()
	else:
		_highlight.set_top_left()
	
	# When the cursor moves, and we already have an active unit selected, we want to update the
	# interactive path drawing.
	if _active_unit and _active_unit.is_selected and _cursor_enabled:
		_unit_path_arrow.draw(_active_unit.cell, new_cell)
		return

# Selects or moves a unit based on where the cursor is.
func _on_cursor_accept_pressed(cell: Vector2) -> void:
	# The cursor's "accept_pressed" means that the player wants to interact with a cell. Depending
	# on the board's current state, this interaction means either that we want to select a unit or
	# that we want to give it a move order.
	if not _active_unit:
		#SoundManager.Menu_Select_Sound()

		player_select_unit(cell)
	elif _active_unit.is_selected and not _units.has(cell):
		_active_path = _unit_path_arrow.current_path
		_move_active_unit(cell)

# Checks for unhandled input, mainly UI cancel actions. Messy.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flop_language"):
		if(TranslationServer.get_locale()=="en"):
			TranslationServer.set_locale("hs")
		elif(TranslationServer.get_locale()=="hs"):
			TranslationServer.set_locale("ja")
		else:
			TranslationServer.set_locale("en")
	if event.is_action_pressed("ui_cancel"):
		if _active_unit:
			if _active_unit.get_state() == "Moved" and (_old_cell):
				_teleport_active_unit(_old_cell)
				
			if _active_unit.get_state() != "Attacking" and _active_unit.get_state() != "Dead":
				_deselect_active_unit()
				_cursor_enabled = true
				_active_ui = null
			
			# Undoes the finalization of the movement

# Sets the active unit to exhausted and disables it.
func _exhaust_active_unit() -> void:
	if _active_unit:
		_cursor_enabled = true
		_active_unit.set_state("Exhausted")
		_deselect_active_unit()

# Callback to check what to do when a unit's state changes.
func _on_unit_state_changed(unit: Unit) -> void:
	var state = unit.get_state()
	if (state == "Exhausted"):
		_check_should_turn_end()
		pass
	elif (state == "Moved"):
		pass
	elif (state == "Dead"):
		_units.erase(unit.cell)
	
# See if everyone in the active faction has moved/acted, and the turn can end.
func _check_should_turn_end():
	var faction_units := get_tree().get_nodes_in_group(_active_faction)
	for unit: Unit in faction_units:
		if not unit.get_state() == "Exhausted":
			return

	_active_faction = "Enemy" if _active_faction == "Player" else "Player"
	
# Refresh a particular faction.
func _refresh_faction(faction: String) -> void:
	# TODO: Validate the states later, or find a better way to do it.
	
	var faction_units := get_tree().get_nodes_in_group(faction)
	for unit: Unit in faction_units:
		unit.set_state("Idle")

# Refresh all factions, taking them from exhausted to normal.
func _refresh_factions() -> void:
	_refresh_faction("Player")
	_refresh_faction("Ally")
	_refresh_faction("Enemy")


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
		_walkable_cells = get_walkable_cells(unit)
		var pathfinder = PathFinder.new(grid, _walkable_cells)
		var path := PackedVector2Array()
		path.resize(9999)
		
		# TODO
		# Find the closest unit of the target faction units.
		for enemy: Unit in target_faction_units:
			var new_path := pathfinder.calculate_point_path(unit.cell, enemy.cell)
			if (not new_path.is_empty() and new_path.size() < path.size()):
				path = new_path
		
		var _patrol_start = _active_unit.find_child("Start")
		var _patrol_end = _active_unit.find_child("End")
		var _patroling = false
		if(_patrol_start and _patrol_end):
			_patroling = true
			var _nearest_cell
			if(!_patrol_start.visited):
				_nearest_cell = _get_closest_cell_from_array(_patrol_start.cell,_walkable_cells)
			else:
				_nearest_cell = _get_closest_cell_from_array(_patrol_end.cell,_walkable_cells)
			path = pathfinder.calculate_point_path(unit.cell, _nearest_cell)
			
		
		# If we can't immediately attack an enemy in range or we're right next to them,
		if path.is_empty() or path.size() == 9999:
				_deselect_active_unit()
				continue
		
		# Shorten the path so you don't go right ONTO your target. 
		# Later we scale this by the attack range of the enemy.
		if(!_patroling):
			path.remove_at(path.size() - 1)
		
		if (path.size() <= 1):		
			_find_targets_in_range()
			if (_active_targets.size() > 0):
				await attack(_active_targets.pick_random())
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
			await attack(_active_targets.pick_random())
			continue
			
		if (_same_cell(_patrol_start, unit)):
			_patrol_start.visited = true
			_patrol_end.visited = false
		
		elif (_same_cell(_patrol_end, unit)):
			_patrol_end.visited = true
			_patrol_start.visited = false
		
	_active_faction = target_faction
	


# Finds all targets in range.
func _find_targets_in_range():
	_active_targets.clear()

	for direction in DIRECTIONS:
		var coordinates: Vector2 = _active_unit.cell + direction
		
		if _units.has(coordinates) and _units.get(coordinates).get_faction() == _active_unit.get_enemy_faction() and _units.get(coordinates) not in _active_targets:
			_active_targets.append(_units[coordinates])

# Adds a menu after moving. Let's make this a builder later or something. This is a mess.
func _add_post_move_ui():
	_active_ui = _action_ui.instantiate()
	
	if (_active_targets.size() > 0):
		_active_ui.setup(_exhaust_active_unit, Callable(), _player_try_attack)
	else:
		_active_ui.setup(_exhaust_active_unit)

# Player: See if there are targets near you, so that you may attack.
func _player_try_attack():
	if (_active_targets.size() <= 0):
		return
	
	_add_attack_ui()

# Adds the attack UI for selecting a target to attack.
func _add_attack_ui():
	_active_ui = _attack_ui.instantiate()
	_active_ui.setup(attack, _active_targets)

func attack(unit: Unit):
	_active_unit.set_state("Attacking")
	_cursor_enabled = false
	var combat_object: CombatObject = load("res://Combat/CombatObject.tscn").instantiate()
	_active_ui = combat_object
	_ui_container.add_child(combat_object)
	combat_object.setup(_active_unit, unit)
	
	await combat_object.attack_finished
	_active_ui = null
	
	_exhaust_active_unit()


# Gets the movement cost of a tile on the map.
func get_movement_cost_at_tile(cell: Vector2):
	var data: TileData = _map.get_cell_tile_data(0, cell)
	if data:
		return data.get_custom_data("Move Cost") as int

# Gets the impassability of a tile on the map. false = passable.
func get_impassable_at_tile(cell: Vector2):
	var data: TileData = _map.get_cell_tile_data(0, cell)
	if data:
		return data.get_custom_data("Impassable") as bool

# Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_walkable_cells(unit: Unit) -> Array:
	return _get_tiles_in_movement_range(unit.cell, unit.move_range)

# Returns an array with all the coordinates of walkable cells based on the `max_distance`.
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	# This is the array of walkable cells the algorithm outputs.
	var array := []
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [cell]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.is_empty():
		var current = stack.pop_back()

		# For each cell, we ensure that we can fill further.
		#
		# The conditions are:
		# 1. We didn't go past the grid's limits.
		# 2. We haven't already visited and filled this cell
		# 3. We are within the `max_distance`, a number of cells.
		# 4. The cell is passable. (BD. was here!) 
		if not grid.is_within_bounds(current):
			continue
		if current in array:
			continue

		# Check passability here.
		if get_impassable_at_tile(current):
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue
	
		# If we meet all the conditions, we "fill" the `current` cell. To be more accurate, we store
		# it in our output `array` to later use them with the UnitPath and UnitOverlay classes.
		array.append(current)
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			# This is an "optimization". It does the same thing as our `if current in array:` above
			# but repeating it here with the neighbors skips some instructions.
			if is_occupied(coordinates):
				continue
			if coordinates in array:
				continue

			# This is where we extend the stack.
			stack.append(coordinates)
	return array

# Returns an array with all the coordinates of walkable cells based on the `movement_range`.
func _get_tiles_in_movement_range(cell: Vector2, movement_range: int):
	var array = _flood_fill(cell, movement_range)
	var pathfinder = PathFinder.new(grid, array)
	return pathfinder.find_tiles_in_range(cell, movement_range)

func _get_closest_cell_from_array(cell: Vector2, walkable_cells: Array):
	var _best_cell = Vector2(-9999, -9999)
	for _current_cell in walkable_cells:
		if((_best_cell-cell).length_squared() > (_current_cell-cell).length_squared()):
			_best_cell = _current_cell
	return _best_cell
	
func _same_cell(unitA, unitB):
	if(unitA == null or unitB == null):
		return false
	return (unitA.cell == unitB.cell)
		
