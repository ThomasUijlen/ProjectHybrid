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
	
	if has_node("Node3D"):
		$Node3D/Decal.texture_albedo = texture
		$Node3D/Decal.texture_emission = texture
#	else:
#		$Image.texture = texture
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
	
	var color = getColor(strongestEmotion)
	label.setColor(color)
	
	$SubViewport.add_child(label)
	label.position = (findPixel(color)/pixels)*1000
	label.position += Vector2.ONE*((0.5/25)*1000)
	var direction = label.position.direction_to(Vector2(500,500))
	label.look_at(label.position - direction)

func findPixel(c : Color):
	var validCoords = []
	
	for x in range(2,pixels-2):
		for y in range(2,pixels-2):
			var coord = Vector2(x,y)
			if image.get_pixel(coord.x, coord.y) == c: continue
			
			var validCount = 0
			validCount += isValid(coord + Vector2.LEFT, c)
			validCount += isValid(coord + Vector2.RIGHT, c)
			validCount += isValid(coord + Vector2.UP, c)
			validCount += isValid(coord + Vector2.DOWN, c)
			
			if validCount > 0: validCoords.append(coord)
	
	if validCoords.size() > 0:
		validCoords.shuffle()
		return validCoords[0]
	else:
		return Vector2(randf_range(0,pixels),randf_range(0,pixels)).floor()

func isValid(pixel : Vector2, color : Color):
	if pixel.x >= pixels || pixel.y >= pixels: return 0
	if image.get_pixel(pixel.x, pixel.y) != color: return 0
	return 1

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

func _input(event):
	if event.is_action_pressed("Up"):
		$Image.scale.x = $Image.scale.x + 0.1
		$Image.scale.y = $Image.scale.y + 0.1
	if event.is_action_pressed("Down"):
		$Image.scale.x = $Image.scale.x - 0.1
		$Image.scale.y = $Image.scale.y - 0.1
