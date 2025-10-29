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

var team : int = 0 :
	get:
		return team
	set(value):
		team = value
		set_team(value)

var team_colors = [Color.RED, Color.BLUE]

@onready var inputs: PlayerInput = $Input
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
@onready var car_model: Node3D = $Car_model
@onready var roof_bounce: RayCast3D = $RoofBounce

var game: Game

func _ready():
	print(multiplayer.get_unique_id(), " - created ", name, " ready")
	global_position = Vector3(randi_range(-8, 8), 5, randi_range(-8, 8))

	if str(name).is_valid_int():
		inputs.set_multiplayer_authority(str(name).to_int())
		focus_camera_on(self)

	await get_tree().process_frame
	rollback_synchronizer.process_settings()
	game = get_node("/root/World/Game")


func set_color(color: Color) -> void:
	var mesh_instance: MeshInstance3D = car_model.get_node("Car") as MeshInstance3D
	var material = mesh_instance.mesh.surface_get_material(0)
	var new_material : StandardMaterial3D = material.duplicate() as StandardMaterial3D
	mesh_instance.set_surface_override_material(0, new_material)
	new_material.albedo_color = color

func set_team(team_id: int) -> void:
	set_color(team_colors[team_id])

func focus_camera_on(cam_target):
	if inputs.is_multiplayer_authority():
		var camera = get_tree().get_root().get_camera_3d()
		camera.target = cam_target

func _process(_delta: float) -> void:
	$Label3D.text = "Speed: %.2f" % linear_velocity.length()

func take_kickoff_position() -> void:
	if game.kickoff_positions.has(name):
		direct_state.transform.origin = game.kickoff_positions[name]
		direct_state.transform.basis = Basis.IDENTITY 
		direct_state.linear_velocity = Vector3.ZERO
		direct_state.angular_velocity = Vector3.ZERO 


		var target = Vector3(0, global_position.y, 0)
		direct_state.transform.basis = Basis.looking_at(target - global_position, Vector3.UP, true)

func _physics_rollback_tick(delta, _tick):

	# Jolt bug workaround - likely https://github.com/godotengine/godot/issues/108656
	# didnt happen in Godot 4.4
	sleeping = false

	if game.kicking_off:
		take_kickoff_position()
		return

	accel_input = - clamp(inputs.motion.y, -1, 1)
	steering_input = - clamp(inputs.motion.x, -1, 1)

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

	#Jump
	if wheels_on_ground > 2 and inputs.jumping:
		var vehicles_up = global_transform.basis.y
		apply_impulse(jump_force * vehicles_up, -vehicles_up)

	#If fallen on roof, roll over
	roof_bounce.force_raycast_update()
	if roof_bounce.is_colliding() and wheels_on_ground == 0:
		apply_torque(Vector3(500,0,500))
