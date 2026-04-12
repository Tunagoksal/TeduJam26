extends Node

signal achivement_unlocked(ach: AchievementData)

@export var achievement_list: Array[AchievementData]
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var achievement_ui = preload("res://scenes/achievement_ui.tscn")

func _ready() -> void:
	var ui_instance = achievement_ui.instantiate()
	add_child(ui_instance)
	

func unlock_achivement(title:String):
	for ach in achievement_list:
		if ach.title == title:
			if not ach.unlocked:
				audio_stream_player.play()	
				ach.unlocked = true
				achivement_unlocked.emit(ach)
				print_debug("achivement unlocked: ", ach.title)
			return
	
