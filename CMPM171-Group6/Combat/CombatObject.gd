# A GUI that comes up when two units fight, that also controls the logic of their fighting. 
# Nice and self-contained.
class_name CombatObject extends HBoxContainer

@export var attack_speed = 0.2
@export var pause_time = 1
@export var nudge_distance = 2

# The PanelContainers that contain their individual HP info, as well as their properties.
@onready var _box1: PanelContainer = $Box1
@onready var _box2: PanelContainer = $Box2

@onready var _health_point = preload("res://Combat/HealthPoint.tscn")

var unit_boxes: Dictionary = {}

var _attacker: Unit
var _target: Unit

var was_setup: bool = false

signal attack_finished

var someone_died: bool

# This function sets up the "Combat Object, adding health points, HP text, and unit name.
func setup(attacker: Unit, target: Unit):
	if was_setup: return
	was_setup = true

	
	_attacker = attacker
	_target = target
	
	var units: Array = [attacker, target]

	for unit in units:
		var box: PanelContainer = _box1 if (unit == attacker) else _box2
		var health_points: HBoxContainer = box.find_child("HealthPoints")
		
		for n in range(unit.stats.max_hp):
			var health_point = _health_point.instantiate()
			health_points.add_child(health_point)
			if (n < unit.stats.hp):
				health_point.texture.current_frame = 1
			
		box.find_child("UnitName").text = unit.name
		box.find_child("HealthPointsText").text = str(unit.stats.hp)
		unit_boxes[unit] = box
		
	fight()
	
# Make the two units fight, with two volleys.
func fight():
	if not was_setup: return
	
	await volley(_attacker, _target)
	if someone_died: return
	await volley(_target, _attacker)
	if someone_died: return

	attack_finished.emit()



# Currently this assumes an attack always hits. Fix this soon.
func volley(attacker: Unit, target: Unit):
	await animate_volley(attacker, target)
	var damage: int = calculate_damage(attacker, target)
	SoundManager.Hit_Sound()
	chip_damage(target, damage)
	await _timer(pause_time)

# Deal actual damage to a unit.
func chip_damage(unit: Unit, damage: int):
	
	
	unit.shake()
	
	var t = create_tween()
	var health_points: HBoxContainer = unit_boxes[unit].find_child("HealthPoints")
	
	var reversed := health_points.get_children()
	reversed.reverse()
	
	
	# Chip off health while you chip off the active elements.
	for element in reversed:
		if element.texture.current_frame == 0: continue
		if damage == -1: break
		element.texture.current_frame = 0
		damage -= 1
		unit.stats.hp -= 1
		await get_tree().create_timer(0.02).timeout
		
		if unit.stats.hp <= 0:
			someone_died = true
			await _timer(pause_time / 2)
			await unit.die()
			attack_finished.emit()

			
	

# Animates the actual battle going on.
func animate_volley(attacker: Unit, target: Unit):
	# await get_tree().create_timer(pause_time).timeout
	var source_pos: Vector2 = attacker.position
	var dest_pos: Vector2 = (attacker.position + target.position) / 2
	# dest_pos = (dest_pos.normalized() * nudge_distance)
	
	var tween = attacker.create_tween()
	tween.tween_property(attacker, "position", dest_pos, attack_speed).from(source_pos).set_trans(Tween.TRANS_BACK)
	await tween.finished
	var tween2 = attacker.create_tween()
	tween2.tween_property(attacker, "position", source_pos, attack_speed).from(dest_pos).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Calculates the damage a unit should take. Will be more sophisticated later.
func calculate_damage(attacker: Unit, target: Unit) -> int:
	return attacker.stats.attack - target.stats.defense

# Hack to make the text update on the menus.
func _process(delta):
	_box1.find_child("HealthPointsText").text = str(_attacker.stats.hp)
	_box2.find_child("HealthPointsText").text = str(_target.stats.hp)	

func _timer(time: float):
	await get_tree().create_timer(time).timeout
