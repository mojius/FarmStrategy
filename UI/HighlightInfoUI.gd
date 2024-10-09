class_name HighlightInfoUI extends Control

@onready var _texture = $"%TextureRect"
@onready var _label_name = $"%UnitName"
@onready var _hp = $"%HealthPoints"
@onready var _hp_text = $"%HealthPointsText"
@onready var _health_point = preload("res://Combat/HealthPoint.tscn")

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
	
