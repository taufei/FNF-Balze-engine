extends Node

var bpmTestMode = false

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	var _c_beat = Conductor.connect("beat_hit", self, "beat_hit")

func _input(event):
	if (event is InputEventKey):
		if (event.pressed):
			match (event.scancode):
				KEY_F1:
					bpmTestMode = !bpmTestMode
				KEY_F4:
					OS.window_fullscreen = !OS.window_fullscreen

func beat_hit():
	if (bpmTestMode):
		get_tree().current_scene.get_node("Music/DebugBPMStream").play()
