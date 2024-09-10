# Represents a unit on the game board.
# The board manages the Unit's position inside the game grid.
# The unit itself is only a visual representation that moves smoothly in the game world.
# We use the tool mode so the `skin` and `skin_offset` below update in the editor.
@tool
class_name Unit
extends Path2D

# Singleton with information about the size of the grid.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

# Unit stats.
@export var stats: Resource = preload("res://Units/Stats.tres")

# Distance to which the unit can walk in cells.
# We'll use this to limit the cells the unit can move to.
@export var move_range := 6

signal state_changed(unit: Unit)

# BD: These are currently a little convoluted since they're basically conflated with groups. 
# We can fix it a little later if you want.
@export_enum("Player", "Ally", "Enemy") var _faction: String = "Player"

func set_faction(value: String):
	remove_from_group("Player")
	remove_from_group("Ally")
	remove_from_group("Enemy")
	_faction = value
	add_to_group(value)

func get_faction() -> String:
	return _faction

# Texture representing the unit.
# With the `tool` mode, assigning a new texture to this property in the inspector will update the
# unit's sprite instantly. See `set_skin()` below.
@export var skin: Texture : set = set_skin
	
# Our unit's skin is just a sprite in this demo and depending on its size, we need to offset it so
# the sprite aligns with the shadow.
@export var skin_offset := Vector2.ZERO : set = set_skin_offset
# The unit's move speed in pixels, when it's moving along a path.
@export var move_speed := 100

# Intensity of the shake from when the unit takes damage.
@export var shake_intensity := 50

# Coordinates of the grid's cell the unit is on.
var cell := Vector2.ZERO : set = set_cell
# Toggles the "selected" animation on the unit.
var is_selected := false : set = set_is_selected

# Through its setter function, the `_is_walking` property toggles processing for this unit.
# See `_set_is_walking()` at the bottom of this code snippet.
var _is_walking := false : set = _set_is_walking

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D
@onready var _shake_timer: Timer = $ShakeTimer

var _anim_state = "idle" :
	set(value):
		_anim_state = value
		_anim_player.play(value)


# BD: Sets whether or not a unit is exhausted.
var _state := "Idle" : set = set_state, get = get_state

# Making this into its own function so maybe later we can do stuff with making the unit grayed out.
func set_state(state: String) -> void:
	_state = state
	state_changed.emit(self)
	if (state == "Exhausted"):
		_anim_state = "exhausted"
	else:
		_anim_state = "idle"

func get_state() -> String:
	return _state

# When changing the `cell`'s value, we don't want to allow coordinates outside the grid, so we clamp
# them.
func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)

# The `is_selected` property toggles playback of the "selected" animation.
func set_is_selected(value: bool) -> void:
	is_selected = value
	if is_selected:
		if(_faction == "Player"):
			#SoundManager.Menu_Select_Sound()
			pass
		_anim_state = "selected"
	else:
		# BD.: Doing this hacky little thing for exhaust.
		if (_anim_state != "exhausted"):
			_anim_state = "idle"
		
# Both setters below manipulate the unit's Sprite node.
# Here, we update the sprite's texture.
func set_skin(value: Texture) -> void:
	skin = value
	# Setter functions are called during the node's `_init()` callback, before they entered the
	# tree. At that point in time, the `_sprite` variable is `null`. If so, we have to wait to
	# update the sprite's properties.
	if not _sprite:
		# The await  keyword allows us to wait until the unit node's `_ready()` callback ended.
		await self.ready
	_sprite.texture = value

# BD: Assumedly this is to move the sprite how we want 
# without moving the position of the actual unit.
func set_skin_offset(value: Vector2) -> void:
	skin_offset = value
	if not _sprite:
		await self.ready
	_sprite.position = value

func _set_is_walking(value: bool) -> void:
	_is_walking = value
	#SoundManager.Walk_Sound_Play()

# Emitted when the unit reached the end of a path along which it was walking.
# We'll use this to notify the game board that a unit reached its destination and we can let the
# player select another unit.
signal walk_finished

func _ready() -> void:
	
	if stats.hp_override:
		stats.hp = stats.override
	else:
		stats.hp = stats.max_hp
	set_faction(_faction)
	
	# We'll use the `_process()` callback to move the unit along a path. Unless it has a path to
	# walk, we don't want it to update every frame. See `walk_along()` below.
	# set_process(false)

	# The following lines initialize the `cell` property and snap the unit to the cell's center on the map.
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	if not Engine.is_editor_hint():
		# We create the curve resource here because creating it in the editor prevents us from
		# moving the unit.
		curve = Curve2D.new()

# When active, moves the unit along its `curve` with the help of the PathFollow2D node.
func _process(delta: float) -> void:
	# Leave the function if we're in-editor.
	if Engine.is_editor_hint(): return
	
	# Add shake if need be.
	var shake_value = Vector2(randf_range(-1,1), randf_range(-1,1)) * _shake_timer.time_left * shake_intensity
	_sprite.offset = Vector2(0,0) + shake_value
	
	if not (_is_walking): return
	
	# Every frame, the `PathFollow2D.offset` property moves the sprites along the `curve`.
	# The great thing about this is it moves an exact number of pixels taking turns into account.
	_path_follow.progress += move_speed * delta

	# When we increase the `offset` above, the `unit_offset` also updates. It represents how far you
	# are along the `curve` in percent, where a value of `1.0` means you reached the end.
	# When that is the case, the unit is done moving.
	if _path_follow.progress_ratio >= 1.0:
		# Setting `_is_walking` to `false` also turns off processing.
		self._is_walking = false
		# Below, we reset the offset to `0.0`, which snaps the sprites back to the Unit node's
		# position, we position the node to the center of the target grid cell, and we clear the
		# curve.
		# In the process loop, we only moved the sprite, and not the unit itself. The following
		# lines move the unit in a way that's transparent to the player.
		_path_follow.progress = 0.00000001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		# Finally, we emit a signal. We'll use this one with the game board.
		emit_signal("walk_finished")
		#SoundManager.Walk_Sound_Stop()
	
# Starts walking along the `path`.
# `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return

	# This code converts the `path` to points on the `curve`. That property comes from the `Path2D`
	# class the Unit extends.
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	# We instantly change the unit's cell to the target position. You could also do that when it
	# reaches the end of the path, using `grid.calculate_grid_coordinates()`, instead.
	# I did it here because we have the coordinates provided by the `path` argument.
	# The cell itself represents the grid coordinates the unit will stand on.
	cell = path[-1]
	# The `_is_walking` property triggers the move animation and turns on `_process()`. See
	# `_set_is_walking()` below.
	self._is_walking = true

func get_enemy_faction() -> String:
	if _faction == ("Player"):
		return ("Enemy")
	elif _faction == ("Enemy"):
		return ("Player")
		
	return ("Enemy")

func die():
	set_state("Dead")	
	_anim_state = "death"
	await _anim_player.animation_finished
	queue_free()

func shake():
	_shake_timer.start()
