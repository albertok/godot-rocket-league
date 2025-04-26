extends BaseNetInput
class_name PlayerInput


var ai_enabled: bool = false
var ai_motion: Vector2 = Vector2()

@export
var motion = Vector2():
	set(value):
		motion = clamp(value, Vector2(-1, -1), Vector2(1, 1))

func _gather():
	if is_multiplayer_authority():
		if ai_enabled:
			motion = ai_motion
		else:
			motion = Input.get_vector("left", "right", "down", "up")
