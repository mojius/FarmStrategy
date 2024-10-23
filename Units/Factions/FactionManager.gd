class_name FactionManager extends Node2D

# Phase animation.
@onready var _phase = preload("res://Juice/Phase.tscn")

signal enable_cursor(bool)
signal next_phase(Phase)
signal grow_plants
signal cpu_turn(String)


# The player's active faction.
var _active_faction : String = "Player" : set = set_active_faction, get = get_active_faction

func get_active_faction():
	return _active_faction

func set_active_faction(value: String) -> void:
	var old_value = _active_faction
	enable_cursor.emit(false)
	
	_active_faction = value
	
	await get_tree().create_timer(0.4).timeout
	
	_refresh_factions()
	var phase: Phase = _phase.instantiate()
	next_phase.emit(phase)
	await phase.done	
	
	if (value == "Player"):
		if (old_value == "Enemy"): grow_plants.emit()
		enable_cursor.emit(true)
	
	if not value == "Player":
		cpu_turn.emit(value)

# Refresh a particular faction.
func _refresh_faction(faction: String) -> void:	
	var faction_units := get_tree().get_nodes_in_group(faction)
	for unit: Unit in faction_units:
		unit.set_state("Idle")


# Refresh all factions, taking them from exhausted to normal.
func _refresh_factions() -> void:
	_refresh_faction("Player")
	_refresh_faction("Ally")
	_refresh_faction("Enemy")

func _get_opposing_faction(faction: String):
	if (faction == "Player" || faction == "Ally"):
		return "Enemy"
	elif (faction == "Enemy"):
		return "Player"

# See if everyone in the active faction has moved/acted, and the turn can end.
func _check_should_turn_end() -> bool:
	var active_faction = get_active_faction()
	var faction_units := get_tree().get_nodes_in_group(active_faction)
	for unit: Unit in faction_units:
		if not unit.get_state() == "Exhausted":
			return false
	var new_faction: String = "Enemy" if active_faction == "Player" else "Player"
	set_active_faction(new_faction)
	return true
