# The purpose of this file is to have a stats object that can easily be passed around for calculations.
class_name Stats extends Resource

# All stats are pretty self-explanatory, except hp_override, 
# which sets HP to a custom value by default besides the maximum.
@export var max_hp: int = 1
@export var hp_override: bool
@export var override: int = 0
@export var attack: int = 1
@export var defense: int = 1
