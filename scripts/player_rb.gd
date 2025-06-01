extends NetworkRigidBody3D

class_name PlayerRB


@export var suspension_rest_dist: float = 0.5
@export var spring_strength: float = 80.0
@export var spring_damper: float = 10.0
@export var wheel_radius: float = 0.33
@export var debug: bool = false
@export var engine_power: float
@export var steering_angle: float = 30.0
@export var front_tire_grip: float = 2.0
@export var rear_tire_grip: float = 2.0
@export var jump_force: float = 30.

var accel_input
var steering_input
var previous_spring_lengths: Array = [0.0, 0.0, 0.0, 0.0]

@onready var inputs: PlayerInput = $Input
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer


func _ready():
	print(multiplayer.get_unique_id(), " - created ", name, " ready")

	global_position = Vector3(randi_range(-8, 8), 5, randi_range(-8, 8))

	if str(name).is_valid_int():
		inputs.set_multiplayer_authority(str(name).to_int())
		focus_camera_on(self)
		
	await get_tree().process_frame
	rollback_synchronizer.process_settings()

func focus_camera_on(cam_target):
	if inputs.is_multiplayer_authority():
		var camera = get_tree().get_root().get_camera_3d()
		camera.target = cam_target

func _process(_delta: float) -> void:
	$Label3D.text = "Speed: %.2f" % linear_velocity.length()
	
func _physics_rollback_tick(delta, _tick):
	accel_input = - inputs.motion.y
	
	steering_input = - inputs.motion.x
	var steering_rotation = steering_input * steering_angle
	
	var fl_wheel = $Wheels/FL_Wheel
	var fr_wheel = $Wheels/FR_Wheel
	
	if steering_rotation != 0:
		var angle = clamp(fl_wheel.rotation.y + steering_rotation, -steering_angle, steering_angle)
		var new_rotation = angle * delta
		
		fl_wheel.rotation.y = lerp(fl_wheel.rotation.y, new_rotation, 0.3)
		fr_wheel.rotation.y = lerp(fr_wheel.rotation.y, new_rotation, 0.3)
	else:
		fl_wheel.rotation.y = lerp(fl_wheel.rotation.y, 0.0, 0.2)
		fr_wheel.rotation.y = lerp(fr_wheel.rotation.y, 0.0, 0.2)

	var wheels_on_ground = 0
	for i in range(4):
		var wheel = $Wheels.get_child(i)
		wheel.previous_spring_length = previous_spring_lengths[i]
		wheel.wheel_tick(delta, _tick)
		if wheel.is_colliding():
			wheels_on_ground += 1
		previous_spring_lengths[i] = wheel.previous_spring_length

	if wheels_on_ground > 2 and inputs.jumping:
		var vehicles_up = global_transform.basis.y
		apply_impulse(jump_force * vehicles_up, -vehicles_up)
