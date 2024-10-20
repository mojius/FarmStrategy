class_name HighlightInfoUI extends Control

@onready var _texture = $"%TextureRect"
@onready var _label_name = $"%UnitName"
@onready var _hp = $"%HealthPoints"
@onready var _hp_text = $"%HealthPointsText"
@onready var _health_point = preload("res://Combat/HealthPoint.tscn")

# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://Map/Grid.tres")

func set_bottom_left():
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	
func set_top_left():
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

func refresh(unit: Unit):
	for node in _hp.get_children():
		_hp.remove_child(node)
	
	for n in range(unit.stats.max_hp):
		var health_point = _health_point.instantiate()
		_hp.add_child(health_point)
		if (n < unit.stats.hp):
			health_point.texture.current_frame = 1
	
	_texture.texture = unit.skin
	_label_name.text = unit.unit_name
	_hp_text.text = str(unit.stats.hp) + " / " + str(unit.stats.max_hp)
	
func cursor_moved(new_cell: Vector2, unit: Unit):
	if unit != null:
		refresh(unit)
		show()
	else: hide()
		
	var center = get_viewport_rect().size / 2
	var pixel_pos = grid.calculate_map_position(new_cell)
	
	if pixel_pos.x < center.x and pixel_pos.y < center.y:
		set_bottom_left()
	else:
		set_top_left()
