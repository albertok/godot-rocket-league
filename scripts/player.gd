extends CharacterBody3D

class_name Player

@export var wheel_base: float = 0.6 # distance between front/rear axles
@export var steering_limit: float = 10.0 # front wheel max turning angle (deg)
@export var engine_power: float = -10.0
@export var braking: float = 12.0
@export var friction: float = -2 # friction coefficient
@export var drag: float = -2 # drag coefficient
@export var max_speed_reverse: float = 4
@export var max_speed_forward: float = 15

# Drifting
@export var slip_speed = 11.0 # lose traction above this speed
@export var traction_slow: float = 0.8 # traction coefficient when not drifting
@export var traction_fast: float = 0.15 # traction coefficient when drifting


# Car state properties
@export var acceleration = Vector3.ZERO # current acceleration
@export var drifting = false
@export var direction = 0.0 # current direction, negative is forward
@export var steer_angle = 0.0 # current wheel angle
@export var driver: String = "player"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var inputs: PlayerInput = $Input
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
#@onready var physics: RapierDriver = get_node(^"../../RapierDriver")

func _ready():
	print(multiplayer.get_unique_id(), " - created ", name, " ready")

	global_position = Vector3(randi_range(0, 3), 2, randi_range(0, 3))

	if str(name).is_valid_int():
		inputs.set_multiplayer_authority(str(name).to_int())
		focus_camera_on(self)
		
	await get_tree().process_frame
	rollback_synchronizer.process_settings()
	NetworkTime.on_tick.connect(on_tick)

func focus_camera_on(cam_target):
	if inputs.is_multiplayer_authority():
		var camera = get_tree().get_root().get_camera_3d()
		camera.target = cam_target

func _process(_delta):
	$Label3D.text = str(name, "\nmovement: ", str(inputs.motion), "\ninput owner: ", str(inputs.get_multiplayer_authority()))

func on_tick(delta, _tick):
	execute_movement(delta, _tick)

func _rollback_tick(delta, _tick, _is_fresh):
	execute_movement(delta, _tick)

func execute_movement(delta, _tick):
	#update the physics server on where we are this tick.
	velocity.y -= gravity * delta
	process_input()

	apply_friction(delta)
	calculate_steering(delta)

	velocity += acceleration * delta

	move_and_slide()

func process_input():
	var turn = inputs.motion.x
	steer_angle = turn * deg_to_rad(steering_limit)
	acceleration = Vector3.ZERO
	if inputs.motion.y > 0:
		acceleration = - transform.basis.z * engine_power
	if inputs.motion.y < 0:
		acceleration = - transform.basis.z * braking

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * drag * delta
	acceleration += drag_force + friction_force


func calculate_steering(delta):
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)

	#Drifting
	# traction
	if not drifting and velocity.length() > slip_speed:
		drifting = true
	if drifting and velocity.length() < slip_speed and steer_angle == 0:
		drifting = false
	var traction = traction_fast if drifting else traction_slow

	direction = new_heading.dot(velocity.normalized())

	if direction > 0: # reverse
		velocity = lerp(velocity, new_heading * min(velocity.length(), max_speed_reverse), traction)
	if direction < 0: # forward
		velocity = lerp(velocity, -new_heading * min(velocity.length(), max_speed_forward), traction)

	look_at(transform.origin + new_heading, transform.basis.y)
