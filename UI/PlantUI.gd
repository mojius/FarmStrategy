class_name PlantUI extends PanelContainer

var _targets := []
var buttons: Array = []

@onready var vbox: VBoxContainer = $"MarginContainer/VBoxContainer"
@onready var cursor_prefab := preload("res://UI/FakeCursor.tscn")
@export var grid: Resource = preload("res://Map/Grid.tres")

var fake_cursor: Node2D


func setup(plant_func: Callable, seed: Seed, targets: Array) -> void:
	self_modulate = Color(0,0,0,0)
	
	fake_cursor = cursor_prefab.instantiate()
	get_tree().root.add_child(fake_cursor)
	
	_targets = targets
	
	var arr: Array[Button] = []
	
	for target in targets:
		var b: Button = Button.new()
		b.name = "Spot"
		b.text = "Spot"
		b.connect("pressed", plant_func.bind(target, seed))
		b.connect("pressed", destroy)
		b.connect("focus_entered", Callable(reposition_fake_cursor).bind(target))
		b.self_modulate = Color(0,0,0,0)
		vbox.add_child(b)
	
		b.grab_focus()
		arr.append(b)
		
	if arr.size() > 1:
		arr.back().focus_neighbor_bottom = arr.front().get_path()
		arr.front().focus_neighbor_top = arr.back().get_path()
	
	self.connect("tree_exiting", destroy)

func reposition_fake_cursor(cell: Vector2):
	fake_cursor.position = grid.calculate_map_position(cell)

func destroy():
	if (is_queued_for_deletion()): return
	fake_cursor.queue_free()
	queue_free()
