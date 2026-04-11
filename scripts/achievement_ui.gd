extends CanvasLayer

@onready var panel = $PanelContainer
@onready var icon_visual = $PanelContainer/Icon
@onready var title_label = $PanelContainer/VBoxContainer/Title

var y_thing
var x_thing
var y_appear

func _ready() -> void:
	AchievementManager.achivement_unlocked.connect(_on_achievement_unlocked)
	
	var screen_size = get_window().size
	
	y_thing = screen_size.y + 50
	x_thing = screen_size.x/2
	y_appear = screen_size.y - panel.size.y * 2
	
	panel.global_position = Vector2(x_thing,y_thing)

func _on_achievement_unlocked(ach:AchievementData):
	var tween  = create_tween()
	
	title_label.text = ach.title
	
	if ach.icon != null:
		icon_visual.texture = ach.icon
		icon_visual.show()
	else:
		icon_visual.hide()
		
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", y_appear, 1.5)
		
	tween.tween_interval(2.0)
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "global_position:y", y_thing, 0.5)
	
