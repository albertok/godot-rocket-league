extends NetworkRigidBody3D

var STARTING_POSITION: Vector3 = Vector3(6.0, 8.0, 0)

var confetti: PackedScene = preload("res://scenes/confetti.tscn")

var entered_goal: bool = false

func _ready():
	set_multiplayer_authority(1, true)
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(on_body_entered)
	$RollbackSynchronizer.process_settings()

func on_body_entered(body: Node) -> void:
	if body.name.begins_with("Goal"):
		entered_goal = true

func _physics_rollback_tick(_delta: float, _tick: int) -> void:
	if entered_goal:
		# Spawn confetti
		var confetti_instance = confetti.instantiate()
		get_tree().root.add_child(confetti_instance)
		confetti_instance.global_position = global_position

		direct_state.transform.origin = STARTING_POSITION
		direct_state.linear_velocity = Vector3.ZERO
		direct_state.angular_velocity = Vector3.ZERO

		entered_goal = false
