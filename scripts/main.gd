extends Node

#const player_scene = preload("res://scenes/player.tscn")
const player_scene = preload("res://scenes/player_rb.tscn")
const ADDRESS = "localhost"
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	if OS.has_feature("editor"):
		var status = _host()
		if status == Error.ERR_CANT_CREATE:
			_join()
			
func _host():
	var status = enet_peer.create_server(PORT)
	if status > 0:
		return status

	enet_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)

	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(client_connected)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())
	
	return status

func client_connected(peer_id):
	print("Client connected: ", peer_id)
	add_player(peer_id)

func _join():
	enet_peer.create_client(ADDRESS, PORT)
	enet_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(connected)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func add_player(peer_id):
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	$Players.add_child(player)

	
func connected():
	print(multiplayer.get_unique_id(), " Connected to server")
	await NetworkTime.after_sync
	
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
