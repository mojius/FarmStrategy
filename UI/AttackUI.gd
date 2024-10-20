class_name AttackUI extends PanelContainer

var _targets := []
var buttons: Array = []

@onready var vbox: VBoxContainer = $"MarginContainer/VBoxContainer"
@onready var cursor_prefab := preload("res://UI/FakeCursor.tscn")
@export var grid: Resource = preload("res://Map/Grid.tres")

var fake_cursor: Node2D

signal attacking

func setup(attack_func: Callable, targets: Array) -> void:

	fake_cursor = cursor_prefab.instantiate()
	get_tree().root.add_child(fake_cursor)
	
	_targets = targets
	
	for target in targets:
		var b: Button = Button.new()
		b.name = target.unit_name
		b.text = target.unit_name
		b.connect("pressed", attack_func.bind(target))
		b.connect("pressed", destroy)
		b.connect("focus_entered", Callable(reposition_fake_cursor).bind(target.cell))
		vbox.add_child(b)
	
		b.grab_focus()
		
	self.connect("tree_exiting", destroy)

func reposition_fake_cursor(cell: Vector2):
	fake_cursor.position = grid.calculate_map_position(cell)

func destroy():
	if (is_queued_for_deletion()): return
	fake_cursor.queue_free()
	queue_free()
