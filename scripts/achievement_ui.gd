extends CanvasLayer

@onready var panel = $PanelContainer
@onready var icon_visual = $PanelContainer/HBoxContainer/Icon
@onready var title_label = $PanelContainer/HBoxContainer/VBoxContainer/Title

func _ready() -> void:
	AchievementManager.achivement_unlocked.connect(_on_achievement_unlocked)

#TODO add some tween, anination and arrange the correct posiiton 
func _on_achievement_unlocked(ach:AchievementData):
	title_label.text = ach.title
	
	if ach.icon != null:
		icon_visual.texture = ach.icon
		icon_visual.show()
	else:
		icon_visual.hide()
		
	panel.global_position = Vector2(400,400)
	
