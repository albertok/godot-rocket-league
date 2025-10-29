extends Node

class_name Game

var kicking_off: bool = false
var kickoff_tick: int = 0
var kickoff_positions = {}

var scores = [0, 0]

@onready var score_board : RichTextLabel = $"../TopCentre/ScoreBoard"
@onready var count_down: RichTextLabel = $"../TopCentre/CountDown"
@onready var ball =  $"../Ball"
@onready var markers = $"../Markers"

func _ready() -> void:
	ball.goal_scored.connect(on_goal_scored)
	NetworkTime.after_tick_loop.connect(update_scoreboard)
	NetworkTime.on_tick.connect(on_tick)
	multiplayer.peer_connected.connect(player_joined)
	update_scoreboard()
	queue_kickoff()

func on_goal_scored(team: int) -> void:
	scores[team] += 1
	queue_kickoff()

func on_tick(_delta: float, tick: int) -> void:
	if kicking_off and tick >= kickoff_tick:
		kicking_off = false

func update_scoreboard() -> void:

	score_board.text = "[outline_size=5][outline_color=black][color=red]%d[/color] - [color=blue]%d[/color][/outline_color][/outline_size]" % [scores[0], scores[1]]

	count_down.text = ""	
	if kicking_off:
		count_down.text = "[outline_size=10][outline_color=black]%d[/outline_color][/outline_size]" % max(0, NetworkTime.ticks_to_seconds(kickoff_tick - NetworkTime.tick))

func queue_kickoff() -> void:
	if not multiplayer.is_server():
		return
		
	await get_tree().create_timer(3.0).timeout
	kicking_off = true
	kickoff_tick = NetworkTime.tick + NetworkTime.seconds_to_ticks(3.5)
	assign_kickoff_positions()

func player_joined(_peer : int) -> void:
	await get_tree().create_timer(1.0).timeout
	assign_kickoff_positions()

func assign_kickoff_positions() -> void:
	
	if not multiplayer.is_server():
		return
	
	var players = get_tree().get_nodes_in_group("players")
	
	kickoff_positions.clear()
	var red_index = 1
	var blue_index = 1
	for player in players:
		if player.team == 0:
			kickoff_positions[player.name] = markers.get_node("r%d" % red_index).global_position
			red_index += 1
		else:
			kickoff_positions[player.name] = markers.get_node("b%d" % blue_index).global_position
			blue_index += 1

	
