extends CanvasLayer

@onready var panel = $Panel
@onready var achievement_label = $Panel/AchievementLabel
@onready var volume_slider = $Panel/VolumeSlider
@onready var overlay = $ColorRect

var is_open := false

func _ready():
	hide()
	
	volume_slider.value_changed.connect(_on_volume_changed)
	AchievementManager.achivement_unlocked.connect(_on_achievement_changed)
	
	update_achievement_text()

func _input(event):
	if event.is_action_pressed("ESC"):
		toggle()

func toggle():
	is_open = !is_open
	visible = is_open
	get_tree().paused = is_open

func _on_achievement_changed(_ach):
	update_achievement_text()

func update_achievement_text():
	var total = AchievementManager.achievement_list.size()
	var unlocked = 0
	
	for ach in AchievementManager.achievement_list:
		if ach.unlocked:
			unlocked += 1
	
	achievement_label.text = "%d / %d" % [unlocked, total]
	
func _on_volume_changed(value: float):
	if value <= 0.01:
		AudioServer.set_bus_volume_db(0, -80) 
	else:
		AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_volume_slider_value_changed(value: float) -> void:
	pass # Replace with function body.
