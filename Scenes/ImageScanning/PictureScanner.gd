extends Node2D

var key = "9026448ec0974609883be3a3fd84b2d2"
var endPoint = "https://legendarischeserver.cognitiveservices.azure.com/"
var host = "legendarischeserver.cognitiveservices.azure.com"

var translationURL = "https://api.nlpcloud.io/v1/nllb-200-3-3b/translation"

var emotionURL = "https://api.nlpcloud.io/v1/distilbert-base-uncased-emotion/sentiment"
var emotionToken = "1730fc0aa4e5d95e8956f79441afa28560abee3e"

var analyzeURL = "vision/v3.2/read/analyze"

var operationLocation = ""

var scannedFiles = []

var scanning = false

var failedAttempts = 0

var t = 3.0
func _process(delta):
	t += delta
	if t > 3.0:
		t = 0.0
		
		var directory = DirAccess.open("res://Webcam/Webcam/Images")
		directory.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				pass
			else:
				if !(".import" in file_name) and (".jpg" in file_name or ".jpeg" in file_name or ".png" in file_name):
					scanImage("res://Webcam/Webcam/Images/"+file_name)
			file_name = directory.get_next()

func scanImage(path):
	if scanning || scannedFiles.has(path): return
	
	print(path)
	scanning = true
	
	var file = FileAccess.open(path,FileAccess.READ)
	var fileContent = file.get_buffer(file.get_length())
	
	$AnalyzeRequest.request_raw(endPoint+analyzeURL, 
	["Host: "+host,
		"Content-Type: application/octet-stream",
		"Ocp-Apim-Subscription-Key: "+key],
	false,
	HTTPClient.METHOD_POST, fileContent)
	
	scannedFiles.append(path)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	operationLocation = headers[1].split(": ")[1]
	
	attemptRead()

func attemptRead():
	await get_tree().create_timer(0.5).timeout
	
	$RetrieveRequest.request(operationLocation, 
	["Ocp-Apim-Subscription-Key: "+key],
	false, 
	HTTPClient.METHOD_GET)

func _on_RetrieveRequest_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	var json = JSON.parse_string(data)
	
	if response_code != 200 || !json.has("analyzeResult"):
		print(response_code)
		attemptRead()
		return
	
	print("--------------")
	print("succesful read "+str(response_code))
	print("--------------")
	var lines = json["analyzeResult"]["readResults"][0]["lines"]
	
	var text = ""
	var lineArray = []
	for line in lines:
		print(line["text"])
		text += line["text"]
		text += " "
		lineArray.append(line["text"])
	
	TextDatabase.addText(lineArray)
	
	translateText(text)

var lastTranslationText = ""
func translateText(text):
	lastTranslationText = text
	$TranslationRequest.request(translationURL, 
	["Content-Type: application/json",
	"Authorization: Token "+emotionToken],
	false, 
	HTTPClient.METHOD_POST, JSON.stringify(
		{"text" : text,
		"source" : "nld_Latn",
		"target" : "eng_Latn"}
		))

func _on_TranslationRequest_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	if response_code != 200:
		print("FAILED TRANSLATION "+str(response_code))
		failedAttempts += 1
		await get_tree().create_timer(5.0+failedAttempts*2).timeout
		translateText(lastTranslationText)
		return
	
	failedAttempts = 0
	var json = JSON.parse_string(data)
	
	print("--------------")
	print("succesful position "+str(response_code))
	print("--------------")
	print(json["translation_text"])
	
	await get_tree().create_timer(3.0).timeout
	
	readEmotions(json["translation_text"])

var lastEmotionText = ""
func readEmotions(text):
	lastEmotionText = text
	$EmotionRequest.request(emotionURL, 
	["Content-Type: application/json",
	"Authorization: Token "+emotionToken],
	false, 
	HTTPClient.METHOD_POST, JSON.new().stringify({"text" : text}))

func _on_EmotionRequest_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	
	if response_code != 200:
		print("FAILED EMOTION SCAN "+str(response_code))
		failedAttempts += 1
		await get_tree().create_timer(3.0+failedAttempts*2).timeout
		readEmotions(lastEmotionText)
		return
	
	failedAttempts = 0
	var json = JSON.parse_string(data)
	
	print("--------------")
	print("succesful emotion analysis "+str(response_code))
	print("--------------")
	
	var emotions = {}
	for emotionData in json["scored_labels"]:
		var emotionName = emotionData["label"]
		var score = emotionData["score"]
		
		TextDatabase.set(emotionName, TextDatabase.get(emotionName)+score)
		TextDatabase.emotionTotal += score
		emotions[emotionName] = score
	
	TextDatabase.addEmotion(emotions)
	TextDatabase.emit_signal("databaseChanged")
	
	scanning = false



