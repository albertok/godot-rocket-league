extends BaseNetInput
class_name PlayerInput


var ai_enabled: bool = false
var ai_motion: Vector2 = Vector2()
var jumping: bool = false
var motion : Vector2 = Vector2.ZERO

func _gather():
	if is_multiplayer_authority():
		if ai_enabled:
			motion = ai_motion
		else:
			var direction = Input.get_vector("left", "right", "down", "up")
			motion = clamp(direction, Vector2(-1, -1), Vector2(1, 1))
			jumping = Input.is_action_pressed("jump")
