# Player-controlled cursor. Allows them to navigate the game grid, select units, and move them.
# Supports both keyboard and mouse (or touch) input.
# The `tool` mode allows us to preview the drawing code you'll see below in the editor.
@tool
class_name Cursor
extends Node2D

@onready var rectangle = $RectangleSprite
@onready var _camera = %Camera

# We'll use signals to keep the cursor decoupled from other nodes.
# When the player moves the cursor or wants to interact with a cell, we emit a signal and let
# another node handle the interaction.

# Emitted when clicking on the currently hovered cell or when pressing "ui_accept".
signal accept_pressed(cell)
# Emitted when the cursor moved to a new cell.
signal moved(new_cell)

# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://Map/Grid.tres")

# Time before the cursor can move again in seconds.
# You can see how we use it in the unhandled input function below.
@export var ui_cooldown := 0.2

var _enabled := true:
	set(value):
		_enabled = value

		if _enabled:
			rectangle.show()
			queue_redraw()
		elif not _enabled:
			rectangle.hide()
			

## Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO:
	set(value):
		# We first clamp the cell coordinates and ensure that we aren't
		#	trying to move outside the grid boundaries
		var new_cell: Vector2 = grid.clamp(value)
		if new_cell.is_equal_approx(cell):
			return

		cell = new_cell
		# If we move to a new cell, we update the cursor's position, emit
		#	a signal, and start the cooldown timer that will limit the rate
		#	at which the cursor moves when we keep the direction key held
		#	down
		position = grid.calculate_map_position(cell)

		emit_signal("moved", cell)
		_timer.start()

@onready var _timer: Timer = $Timer

# When the cursor enters the scene tree, we snap its position to the centre of the cell and we
# initialise the timer with our ui_cooldown variable.
func _ready() -> void:
	_timer.wait_time = ui_cooldown
	position = grid.calculate_map_position(cell)

func _unhandled_input(event: InputEvent) -> void:
	if not _enabled: return
	# If the user moves the mouse, we capture that input and update the node's cell in priority.
	if event is InputEventMouseMotion:
		self.cell = grid.calculate_grid_coordinates((event.position / _camera.zoom) + _camera.offset)
	# If we are already hovering the cell and click on it, or we press the enter key, the player
	# wants to interact with that cell.
	elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		#  In that case, we emit a signal to let another node handle that input. The game board will
		#  have the responsibility of looking at the cell's content.
		emit_signal("accept_pressed", cell)
		
		get_viewport().set_input_as_handled()

	# The code below is for the cursor's movement.
	# The following lines make some preliminary checks to see whether the cursor should move or not
	# if the user presses an arrow key.
	var should_move := event.is_pressed()
	# If the player is pressing the key in this frame, we allow the cursor to move. If they keep the
	# keypress down, we only want to move after the cooldown timer stops.
	if event.is_echo():
		should_move = should_move and _timer.is_stopped()

	# And if the cursor shouldn't move, we prevent it from doing so.
	if not should_move:
		return

	# Here, we update the cursor's current cell based on the input direction. See the set_cell()
	# function below to see what changes that triggers.
	if event.is_action("ui_right"):
		self.cell += Vector2.RIGHT
	elif event.is_action("ui_up"):
		self.cell += Vector2.UP
	elif event.is_action("ui_left"):
		self.cell += Vector2.LEFT
	elif event.is_action("ui_down"):
		self.cell += Vector2.DOWN
	
	# Currently this doesn't do anything because our maps are just too big.
	if (grid.calculate_map_position(self.cell).x > (get_viewport_rect().size.x + _camera.offset.x)):
		_camera.offset.x += grid.cell_size.x
	if (grid.calculate_map_position(self.cell).x < (_camera.offset.x)):
		_camera.offset.x -= grid.cell_size.x
	if (grid.calculate_map_position(self.cell).y > (get_viewport_rect().size.y + _camera.offset.y)):
		_camera.offset.y += grid.cell_size.y
	if (grid.calculate_map_position(self.cell).y < (_camera.offset.y)):
		_camera.offset.y -= grid.cell_size.y		



# This function controls the cursor's current position.
func set_cell(value: Vector2) -> void:
	# We first clamp the cell coordinates and ensure that we weren't trying to move outside the
	# grid's boundaries.
	var new_cell: Vector2 = grid.clamp(value)
	if new_cell.is_equal_approx(cell):
		return

	cell = new_cell
	# If we move to a new cell, we update the cursor's position, emit a signal, and start the
	# cooldown timer that will limit the rate at which the cursor moves when we keep the direction
	# key down.
	position = grid.calculate_map_position(cell)
	emit_signal("moved", cell)
	_timer.start()


func _on_cursor_enable(enabled):
	_enabled = enabled
