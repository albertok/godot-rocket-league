extends Node3D

@onready var inputs: PlayerInput = get_parent().get_node("Input")
@onready var ball: Node3D = get_tree().get_root().get_node("World/Ball")

# Turning circle compensation
const MIN_DISTANCE_FROM_BALL: float = 30.0
const ALIGNMENT_THRESHOLD: float = 0.5

# Stuff to get unstuck
const STUCK_THRESHOLD: float = 0.2
const STUCK_TIME: float = 3.0
const REVERSE_DURATION: float = 0.5 #
var last_position: Vector3 = Vector3()
var stuck_timer: float = 0.0
var reverse_timer: float = 0.0

func _ready() -> void:
	inputs.ai_enabled = true
	NetworkTime.on_tick.connect(_on_tick)


func _input(event: InputEvent) -> void:
	# Disable AI if the player presses any key
	if event is InputEventKey and event.pressed:
		inputs.ai_enabled = false


func _on_tick(_delta: float, _tick: int) -> void:
	if not ball:
		return

	if stuck_check(_delta):
		return

	# Calculate direction and distance to the ball
	var car_direction = global_transform.basis.z.normalized()
	var direction_to_ball = (ball.global_position - global_position).normalized()
	var cross = car_direction.cross(direction_to_ball).y

	var steering = 0
	if cross > 0.1:
		steering = -1 # Steer right
	elif cross < -0.1:
		steering = 1 # Steer left

	inputs.ai_motion = Vector2(steering, 1)

func stuck_check(_delta) -> bool:
	# Check if the car is stuck
	var distance_moved = global_position.distance_to(last_position)
	if distance_moved < STUCK_THRESHOLD:
		stuck_timer += _delta
	else:
		stuck_timer = 0.0 # Reset the timer if were moving

	last_position = global_position

	# reverse if stuck
	if stuck_timer >= STUCK_TIME:
		reverse_timer = REVERSE_DURATION
	stuck_timer = min(stuck_timer, STUCK_TIME)

	if reverse_timer > 0.0:
		reverse_timer -= _delta
		inputs.ai_motion = Vector2(0, -1) # Reverse out
		return true

	return false
