extends CanvasLayer

@onready var panel = $PanelContainer
@onready var icon_visual = $PanelContainer/HBoxContainer/Icon
@onready var title_label = $PanelContainer/HBoxContainer/Title

var y_thing
var x_thing
var y_appear

var popup_queue: Array[AchievementData] = []
var is_showing: bool = false

func _ready() -> void:
	AchievementManager.achivement_unlocked.connect(_on_achievement_unlocked)
	
	# Wait one frame so the PanelContainer can calculate its real size
	await get_tree().process_frame
	
	_update_positions()
	
	# Optional: Re-calculate if the window is resized
	get_viewport().size_changed.connect(_update_positions)

func _update_positions() -> void:
	# Use viewport_rect for internal coordinate consistency
	var screen_size = get_viewport().get_visible_rect().size
	
	# Logic fix: Use panel.size.x for horizontal centering, not size.y!
	x_thing = (screen_size.x / 2.0) - (panel.size.x / 2.0)
	y_thing = screen_size.y + 100
	y_appear = screen_size.y - (panel.size.y * 1.5)
	
	# If not currently animating, snap to the hidden position
	if not is_showing:
		panel.global_position = Vector2(x_thing, y_thing)

func _on_achievement_unlocked(ach:AchievementData):
	
	popup_queue.append(ach)
	
	if not is_showing:
		_show_next()
		
func _show_next():
	
	if popup_queue.is_empty():
		is_showing = false
		return
		
	is_showing = true
	
	var ach = popup_queue.pop_front()
	
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
		
	tween.tween_interval(1.5)
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "global_position:y", y_thing, 0.5)
	
	tween.finished.connect(_show_next)
	
