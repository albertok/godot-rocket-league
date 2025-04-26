extends RayCast3D

class_name RayWheel

@onready var car: RigidBody3D = get_parent().get_parent()
@onready var wheel = $Wheel

var previous_spring_length: float = 0.0

@export var is_front_wheel: bool

func _ready():
	add_exception(car)

func wheel_tick(delta, _tick):
	force_raycast_update()
	
	if is_colliding():
		var collision_point = get_collision_point()
	
		suspension(delta, collision_point)
		acceleration(collision_point)
		
		apply_z_force(collision_point)
		apply_x_force(delta, collision_point)
		
		set_wheel_position(to_local(get_collision_point()).y + car.wheel_radius)
		rotate_wheel(delta)
	else:
		set_wheel_position(-car.suspension_rest_dist)
		

func apply_x_force(delta, collision_point):
	var dir: Vector3 = global_basis.x
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	var tire_world_vel := state.get_velocity_at_local_position(global_position - car.global_position)
	var lateral_vel: float = dir.dot(tire_world_vel)
	
	var grip = car.rear_tire_grip
	
	if is_front_wheel:
		grip = car.front_tire_grip
		
	var desired_vel_change: float = - lateral_vel * grip
	var x_force = desired_vel_change / delta
	
	car.apply_force(dir * x_force, collision_point - car.global_position)
	
	if car.debug:
		DebugDraw3D.draw_arrow(global_position, global_position + (dir * x_force / 20), Color.RED, 0.1, true)

	
func apply_z_force(collision_point):
	var dir: Vector3 = global_basis.z
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	var tire_world_vel := state.get_velocity_at_local_position(global_position - car.global_position)
	var z_force = dir.dot(tire_world_vel) * car.mass / 10
	
	car.apply_force(-dir * z_force, collision_point - car.global_position)
	
	var point = Vector3(collision_point.x, collision_point.y + car.wheel_radius, collision_point.z)
	
	if car.debug:
		DebugDraw3D.draw_arrow(point, point + (-dir * z_force / 2), Color.BLUE_VIOLET, 0.1, true)
		
		
func set_wheel_position(new_y_position: float):
	wheel.position.y = lerp(wheel.position.y, new_y_position, 0.6)
		
		
func rotate_wheel(delta: float):
	var dir = car.basis.z
	var rotation_direction = 1 if car.linear_velocity.dot(dir) > 0 else -1
	
	wheel.rotate_x(rotation_direction * car.linear_velocity.length() * delta)
	
	
func acceleration(collision_point):
	if is_front_wheel:
		return
	
	var accel_dir = - global_basis.z
	
	var torque = car.accel_input * car.engine_power
	
	var point = Vector3(collision_point.x, collision_point.y, collision_point.z)
	
	car.apply_force(accel_dir * torque, point - car.global_position)
	
	if car.debug:
		DebugDraw3D.draw_arrow(point, point + (accel_dir * torque / 20), Color.BLUE, 0.1, true)


func suspension(delta, collision_point):
	# the direction the force will be applied
	var susp_dir = global_basis.y
	
	var raycast_origin = global_position
	var raycast_dest = collision_point
	var distance = raycast_dest.distance_to(raycast_origin)
	
	var spring_length = clamp(distance - car.wheel_radius, 0, car.suspension_rest_dist)
	
	var spring_force = car.spring_strength * (car.suspension_rest_dist - spring_length)
	
	var spring_velocity = (previous_spring_length - spring_length) / delta
	
	var damper_force = car.spring_damper * spring_velocity
	
	var suspension_force = basis.y * (spring_force + damper_force)
	
	previous_spring_length = spring_length
	
	var point = Vector3(collision_point.x, collision_point.y + car.wheel_radius, collision_point.z)
	
	car.apply_force(susp_dir * suspension_force, point - car.global_position)
	
	if car.debug:
		DebugDraw3D.draw_arrow(global_position, to_global(position + Vector3(-position.x, (suspension_force.y / 20), -position.z)), Color.GREEN, 0.1, true)
		DebugDraw3D.draw_line_hit_offset(global_position, to_global(position + Vector3(-position.x, -1, -position.z)), true, distance, 0.2, Color.RED, Color.RED)
