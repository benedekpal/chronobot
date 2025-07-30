extends Node

var BACKGROUBND = Color(0.44, 0.12, 0.52, 1.00)

func _ready():
	RenderingServer.set_default_clear_color(BACKGROUBND)
