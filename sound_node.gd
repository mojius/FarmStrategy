extends Node

func Walk_Sound_Play():
	$"WalkSound".play()
	
func Walk_Sound_Stop():
	$"WalkSound".stop()

func Cursor_Move_Sound():
	$"CursorMoveSound".play()

func Hit_Sound():
	var rand = randi() % 6
	
	if(rand == 0):
		$"HitSound1".play()
	elif (rand == 1):
		$"HitSound2".play()
	elif (rand == 3):
		$"HitSound3".play()
	elif (rand == 4):
		$"HitSound4".play()
	else:
		$"HitSound5".play()

func Death_Remove_Sound():
	var rand = randi() % 2
	
	if(rand == 0):
		$"DeathFwooshSound1".play()
	else:
		$"DeathFwooshSound2".play()

func Miss_Sound():
	$"AttackMissSound".play()

func Menu_Select_Sound():
	$"MenuSelectSound?".play()
