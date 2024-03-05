class_name Phase extends Node2D

@onready var sprite = $Sprite2D

signal done

const TIME_TAKEN = 0.2

func _ready():
	position.x = get_viewport().size.x + sprite.texture.get_width()
	position.y = get_viewport_rect().get_center().y
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", Vector2(0 - sprite.texture.get_width(), get_viewport_rect().get_center().y), TIME_TAKEN).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT_IN)
	await tween.finished
	done.emit()
	
