class_name HealthPlantFruit extends Item 
@export var heal_amount: int

func use(unit: Unit):
	super.use(unit)
	unit.heal_damage(heal_amount)
	unit.item_used.emit(self)
	
	
