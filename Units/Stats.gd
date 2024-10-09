# The purpose of this file is to have a stats object that can easily be passed around for calculations.
class_name Stats extends Resource

# All stats are pretty self-explanatory, except hp_override, 
# which sets HP to a custom value by default besides the maximum.
@export var max_hp: int = 1
@export var override_HP: bool
var hp: int = 0
@export var hp_override: int = 0



func set_hp(_hp: int) -> void:
	hp = _hp
	return
