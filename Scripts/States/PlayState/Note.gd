extends Node2D

const SCROLL_DISTANCE = 1280 # units
var SCROLL_TIME = Conductor.SCROLL_TIME # sec

enum Note {Left, Down, Up, Right}

export (Note) var note_type = Note.Left

var strum_lane
var strum_time
var sustain_length = 0
var must_hit = false

var missed = false
var playState

var holdNote = false
var wasHit = false
var held = false

var mine = false

var key = "left"

onready var holdSprs = {
	"left": [preload("res://Assets/Sprites/Notes/Holds/left_line.png"), preload("res://Assets/Sprites/Notes/Holds/left_end.png")],
	"down": [preload("res://Assets/Sprites/Notes/Holds/down_line.png"), preload("res://Assets/Sprites/Notes/Holds/down_end.png")],
	"up": [preload("res://Assets/Sprites/Notes/Holds/up_line.png"), preload("res://Assets/Sprites/Notes/Holds/up_end.png")],
	"right": [preload("res://Assets/Sprites/Notes/Holds/right_line.png"), preload("res://Assets/Sprites/Notes/Holds/right_end.png")]
}

func _ready():
	var songSpeed = get_tree().current_scene.current_scene.speed
	SCROLL_TIME = SCROLL_TIME / songSpeed
	
	playState = get_tree().current_scene.current_scene
	
	if (visible):
		$Tween.interpolate_property(self, "position:y", SCROLL_DISTANCE * Conductor.scroll_speed, 0, SCROLL_TIME / Conductor.scroll_speed)
		$Tween.start()
	
	match note_type:
		Note.Left:
			key = "left"
		Note.Down:
			key = "down"
		Note.Up:
			key = "up"
		Note.Right:
			key = "right"
	
	$Line2D.texture = holdSprs[key][0]
	
	if (sustain_length > 0):
		holdNote = true
	
	if (mine):
		$Sprite.modulate = Color.black
	
func _on_Tween_tween_completed(_object, _key):
	if (strum_lane != null):
		if (missed):
			if (!mine):
				note_miss(true)
			else:
				queue_free()
		
		if (!must_hit && !mine || Settings.botPlay && !mine):
			note_hit(0)
		else:
			missed = true
			$Tween.interpolate_property(self, "position:y", 0, -SCROLL_DISTANCE * Conductor.scroll_speed, SCROLL_TIME / Conductor.scroll_speed)
			
			if (sustain_length <= 0):
				$Tween.start()

func note_hit(timing):
	var animPlayer = strum_lane.get_node("AnimationPlayer")
	animPlayer.stop()
	animPlayer.play("hit")
	
	if (!wasHit):
		if (!mine):
			playState.on_hit(must_hit, note_type, timing)
		else:
			note_miss(false)
	
	if (!holdNote):
		queue_free()
	else:
		wasHit = true
		held = true
		
		$Sprite.visible = false
		$Tween.stop_all()
	
func note_miss(passed):
	playState.on_miss(must_hit, note_type, passed)
	
	queue_free()

func _process(_delta):
	if (missed && $Tween.tell() > 0.2):
		$Tween.remove_all()
		if (!mine):
			note_miss(true)
	
	if (Settings.downScroll):
		scale.y = -1
		
	if (holdNote):
		var multi = 1
		if (Settings.downScroll):
			multi = -1
		
		# awesome hold note math magic by Scarlett
		var lineY = (sustain_length * (SCROLL_DISTANCE * Conductor.scroll_speed * Conductor.scroll_speed / SCROLL_TIME) * multi) - holdSprs[key][1].get_height()
		if (lineY <= 0):
			lineY = 0
		
		$Line2D.points[1] = Vector2(0, lineY)
		update()
		
	if (held):
		var animPlayer = strum_lane.get_node("AnimationPlayer")
		animPlayer.play("hit")
		
		sustain_length -= _delta
		
		if (sustain_length <= 0):
			queue_free()
			
		position.y = strum_lane.position.y
		
		var character = playState.EnemyCharacter
		if (must_hit):
			character = playState.PlayerCharacter
			
		character.idleTimer = 0.2
		
		var animName = playState.player_sprite(note_type, "")
		if (character.get_node("AnimationPlayer").get_current_animation_position() >= 0.18):
			character.play(animName)
		
		if (must_hit && !Settings.botPlay):
			if (!Input.is_action_pressed(key)):
				held = false
				animPlayer.play("idle")
				$Tween.resume_all()
	
	$Sprite.frame = note_type

func _draw():
	if (holdNote):
		var pos = Vector2($Line2D.points[1].x - 25, $Line2D.points[1].y)
		
		var lineHeight = clamp($Line2D.points[1].y, 0, holdSprs[key][1].get_height())
		
		var size = Vector2(holdSprs[key][1].get_size().x, lineHeight)
		var rect = Rect2(pos, size)
		
		draw_texture_rect(holdSprs[key][1], rect, false, $Line2D.default_color)
