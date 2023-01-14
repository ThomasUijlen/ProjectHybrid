extends Node2D

var columns = [[],[],[],[]]

var labelScene = load("res://Scenes/Visuals/PostIt/postit.tscn")

var image : Image
@export var pixels = 10

func _ready():
	TextDatabase.connect("databaseChanged",Callable(self,"spawnLabel"))
	TextDatabase.connect("databaseChanged",Callable(self,"updateEmotionCircle"))
	image = load("res://icon.png").get_image()
	
	image.resize(pixels, pixels)
	image.fill(Color.WHITE)
	
	randomize()
	setPixelColor(Vector2.ZERO, Color.WHITE)
	
#	for i in range(20):
#		setPixelColor(Vector2(randf_range(0.0,1.0), randf_range(0.0,1.0)), Color.RED)

func updateEmotionCircle():
	var emotions = ["joy", "love", "surprise", "sadness", "fear", "anger"]
	
	var tween = get_tree().create_tween()
#	tween.set_ease(Tween.EASE_OUT_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	
	for emotion in emotions:
		var score = TextDatabase.get(emotion)
		
		tween.tween_property($SubViewport/EmotionCircle.material, "shader_param/"+emotion+"Amount", score, 2.0)
	

func _process(delta):
	var image : Image = $SubViewport.get_texture().get_image()
	var texture : Texture = ImageTexture.create_from_image(image)
	$Node3D/Decal.texture_albedo = texture
	$Node3D/Decal.texture_emission = texture
#		$EmotionCircle.material.set("shader_param/"+emotion+"Amount", score)

func spawnLabel():
	var label = labelScene.instantiate()
	label.setText(TextDatabase.linesList[0])
	
	var strongestEmotion = ""
	var strongestScore = 0.0
	for emotion in TextDatabase.emotionsList[0]:
		var score = TextDatabase.emotionsList[0][emotion]
		if strongestEmotion == "" || score > strongestScore:
			strongestScore = score
			strongestEmotion = emotion
	
	label.setColor(getColor(strongestEmotion))
	
	$SubViewport.add_child(label)
	label.position = Vector2(randf_range(0,1000),randf_range(0,1000))
	var direction = label.position.direction_to(Vector2(500,500))
	label.look_at(label.position - direction)


func setPixelColor(rawPosition : Vector2, color : Color):
	rawPosition /= 1000.0
	var imagePosition := rawPosition*pixels
	imagePosition = imagePosition.floor()
	
	image.set_pixel(imagePosition.x, imagePosition.y, color)
	
	$SubViewport/EmotionPixels.texture = ImageTexture.create_from_image(image)

func getColor(emotion):
	var c : Color = Color.BLACK
	if emotion == "joy":
		c = Color("FFBE0B")
	if emotion == "surprise":
		c = Color("FFBE0B")
	if emotion == "love":
		c = Color("FF006E")
	if emotion == "sadness":
		c = Color("3A86FF")
	if emotion == "anger":
		c = Color("a4243b")
	if emotion == "fear":
		c = Color("8338EC")
	
	return c
