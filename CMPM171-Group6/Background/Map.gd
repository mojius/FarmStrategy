# Deals with the tileset itself and impassable/extra movement cost tiles.

class_name Map extends TileMap

# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://GameBoard/Grid.gd")

# This constant represents the directions in which a unit can move on the board.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]


