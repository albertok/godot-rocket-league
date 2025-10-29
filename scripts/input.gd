extends BaseNetInput
class_name PlayerInput


var ai_enabled: bool = false
var ai_motion: Vector2 = Vector2()
var ai_jumping: bool = false
var jumping: bool = false
var motion : Vector2 = Vector2.ZERO

func _gather():
	if is_multiplayer_authority():
		if ai_enabled:
			motion = ai_motion
			jumping = ai_jumping
		else:
			motion = Input.get_vector("left", "right", "down", "up")
			jumping = Input.is_action_pressed("jump")
