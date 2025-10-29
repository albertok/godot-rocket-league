extends Label

var game : Game = null

func _ready():
	NetworkTime.on_tick.connect(_tick)
	game = get_node("/root/World/Game")


var data_sent_rate = 0.0
var data_received_rate = 0.0
var current_time = 0.0
var last_time = 0.0

func perf(type: String):
	match type:
		"fps":
			return Performance.get_monitor(Performance.TIME_FPS)
		"process":
			return Performance.get_monitor(Performance.TIME_PROCESS)
		"draw_calls":
			return Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)

func _tick(_delta: float, _t: int):
	var type = "Server"
	if not multiplayer.is_server():
		type = "Client"
		
	text = "%s - %s" % [type, multiplayer.get_unique_id()]
	text += "\nFPS: %s " % perf("fps")
	text += "\ntick: %s " % NetworkTime.tick
	
	if not multiplayer.is_server():
		# Grab latency to server and display
		var enet = multiplayer.multiplayer_peer as ENetMultiplayerPeer
		if enet == null:
			return
			
		var server = enet.get_peer(1)
		var _mean_rtt = server.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)

		current_time = Time.get_ticks_msec() / 1000.0

		if int(current_time) > int(last_time):
			data_sent_rate = enet.get_host().pop_statistic(ENetConnection.HostStatistic.HOST_TOTAL_SENT_DATA)
			data_received_rate = enet.get_host().pop_statistic(ENetConnection.HostStatistic.HOST_TOTAL_RECEIVED_DATA)
			last_time = current_time

		text += "\nRTT: %s " % _mean_rtt
		text += "\nData - up: %s Kbps | down: %s Kbps" % [int(data_sent_rate * 0.008), int(data_received_rate * 0.008)]

	# # View input submission status
	# var players = get_tree().get_nodes_in_group("players")
	# var submissions = NetworkRollback.get_input_submissions()
	# for player in players:
	# 	text += "\n%s - last input: %s - %s" % [player.name, submissions.get(player), NetworkRollback.has_input_for_tick(player, NetworkRollback.tick)]
