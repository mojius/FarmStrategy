extends Node

var mute = false;

func Walk_Sound_Play():
	if(mute == false):
		$"WalkSound".play()
	
func Walk_Sound_Stop():
	if(mute == false):
		$"WalkSound".stop()

func Cursor_Move_Sound():
	if(mute == false):
		$"CursorMoveSound".play()

func Hit_Sound():
	if(mute == false):
		$"HitSound4".play()

func Death_Remove_Sound():
	if(mute == false):
		$"DeathFwooshSound2".play()

func Miss_Sound():
	if(mute == false):
		$"AttackMissSound".play()

func Menu_Select_Sound():
	if(mute == false):
		$"MenuSelectSound?".play()
	
func Phase_Change_Sound():
	if(mute == false):
		$"PhaseChangeSound".play()
