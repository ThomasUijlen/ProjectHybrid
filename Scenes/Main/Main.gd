extends Node2D

var columns = [[],[],[],[]]

var labelScene = load("res://Scenes/Visuals/Text/TextLabel.tscn")

func _ready():
	TextDatabase.connect("databaseChanged", self, "spawnLabel")
	TextDatabase.connect("databaseChanged", self, "updateEmotionCircle")

func updateEmotionCircle():
	var emotions = ["joy", "love", "surprise", "sadness", "fear", "anger"]
	
	var tween = get_tree().create_tween()
#	tween.set_ease(Tween.EASE_OUT_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	
	for emotion in emotions:
		var score = TextDatabase.get(emotion)
		
		tween.tween_property($EmotionCircle.material, "shader_param/"+emotion+"Amount", score, 2.0)
#		$EmotionCircle.material.set("shader_param/"+emotion+"Amount", score)

func spawnLabel():
	var label = labelScene.instance()
	label.setText(TextDatabase.linesList[0])
	add_child(label)
	addToColumn(label)

func addToColumn(newLabel):
	var c = null
	var i = 0
	for ci in range(columns.size()):
		var column = columns[ci]
		if c == null or column.size() < c.size():
			c = column
			i = ci
	
	c.push_front(newLabel)
	newLabel.position.x = (1920.0/columns.size())*i + 40.0
	newLabel.position.y = -300
	
	for li in range(c.size()):
		var label = c[li]
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(label, "position", label.position + Vector2(0,li*320) + (Vector2.ZERO if li > 0 else Vector2(0,300+320)), 2.0)
