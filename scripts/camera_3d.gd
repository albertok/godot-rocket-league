extends Camera3D

@export var target: Node3D
@export var height: float = 1.5
@export var target_distance: float = 5.0
@export var smooth_speed: float = 5.0

var current_position: Vector3
var current_rotation: Basis

func _process(delta):
	if !target:
		return

	var target_pos = target.position
	var target_direction = target.global_transform.basis.z
	var desired_position = target_pos - target_direction * target_distance

	desired_position.y = target_pos.y + height
	current_position = current_position.lerp(desired_position, smooth_speed * delta)
	position = current_position

	var desired_rotation = Transform3D().looking_at(target_pos - position, Vector3.UP).basis
	current_rotation = current_rotation.slerp(desired_rotation, 2. * smooth_speed * delta)
	global_transform.basis = current_rotation
