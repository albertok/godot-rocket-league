extends NetworkRigidBody3D

class_name Ball

signal goal_scored(team: int)

var STARTING_POSITION: Vector3 = Vector3(6.0, 8.0, 0)

var confetti: PackedScene = preload("res://scenes/confetti.tscn")

var entered_goal: bool = false
var announced_goal: bool = false
var entered_goal_tick: int = 0
var reset_tick : int = 0
var goal_team: int = 0


func _ready():
	set_multiplayer_authority(1, true)
	contact_monitor = true
	max_contacts_reported = 8
	NetworkTime.on_tick.connect(on_tick)
	$RollbackSynchronizer.process_settings()

func is_confirmed_tick(tick: int) -> bool:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if tick > NetworkRollback.get_latest_input_tick(player):
			return false
	return true

		
func _physics_rollback_tick(_delta: float, tick: int) -> void:
	if tick == reset_tick:
		reset()
		return

func entered_goal_area(area: Area3D, tick: int) -> void:
	entered_goal = true
	entered_goal_tick = tick
	goal_team = int(area.name.right(1))

func on_tick(_delta: float, tick: int) -> void:

	if entered_goal and not announced_goal:
		# Check that no player actions can alter the outcome
		if is_confirmed_tick(entered_goal_tick):

			goal_scored.emit(goal_team)
			entered_goal = false
			announced_goal = true

			# Spawn confetti and hide the ball
			var confetti_instance = confetti.instantiate()
			get_tree().root.add_child(confetti_instance)
			confetti_instance.global_position = global_position
			hide()

			reset_tick = tick + NetworkTime.seconds_to_ticks(5.)


func reset() -> void:
	show()
	entered_goal = false
	announced_goal = false
	direct_state.transform.origin = STARTING_POSITION
	direct_state.linear_velocity = Vector3.ZERO
	direct_state.angular_velocity = Vector3.ZERO 
