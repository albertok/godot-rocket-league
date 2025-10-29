extends Area3D

func _ready():
	NetworkRollback.on_process_tick.connect(on_rollback_tick)

func on_rollback_tick(tick : int) -> void:
	
	for body in get_overlapping_bodies():
		if body is Ball:
			body.entered_goal_area(self, tick)

		
