extends Node


func Walk_Sound_Play():
	$"WalkSound".play()
	
func Walk_Sound_Stop():
	$"WalkSound".stop()

func Cursor_Move_Sound():
	$"CursorMoveSound".play()

func Hit_Sound():
	$"HitSound4".play()

func Death_Remove_Sound():
	$"DeathFwooshSound2".play()

func Miss_Sound():
	$"AttackMissSound".play()

func Menu_Select_Sound():
	$"MenuSelectSound?".play()
	
func Phase_Change_Sound():
	$"PhaseChangeSound".play()
