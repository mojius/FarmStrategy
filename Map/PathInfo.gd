class_name PathInfo extends RefCounted

var start_cell := Vector2(-1,-1)
var target_cell := Vector2(-1, -1)
var max_distance := 1
var is_player := false
var ignore_terrain := false
var unlimited_range := false


func _init(
			_start_cell: Vector2, 
			_target_cell: Vector2, 
			_max_distance: int, 
			_is_player := false, 
			_ignore_terrain := false,
			_unlimited_range := false):
				
	start_cell = _start_cell
	target_cell = _target_cell
	max_distance = _max_distance
	is_player = _is_player
	ignore_terrain = _ignore_terrain
	unlimited_range = _unlimited_range
