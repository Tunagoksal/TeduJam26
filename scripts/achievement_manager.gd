extends Node

signal achivement_unlocked(ach: AchievementData)

@export var achievement_list: Array[AchievementData]

func unlock_achivement(title:String):
	for ach in achievement_list:
		if ach.title == title:
			ach.unlocked = true
			achivement_unlocked.emit(ach)
			print_debug("achivement unlocked: ", ach.title)
	
