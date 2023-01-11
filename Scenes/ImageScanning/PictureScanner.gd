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
var directory = Directory.new()

var scanning = false

var t = 3.0
func _process(delta):
	t += delta
	if t > 3.0:
		t = 0.0
		
		directory.open("res://Webcam/Webcam/Images")
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				pass
			else:
				if !(".import" in file_name) and (".jpg" in file_name or ".jpeg" in file_name):
					scanImage("res://Webcam/Webcam/Images/"+file_name)
			file_name = directory.get_next()

func scanImage(path):
	if scanning || scannedFiles.has(path): return
	
	var file = File.new()
	file.open(path,File.READ)
	var fileContent = file.get_buffer(file.get_len())
	
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
	yield(get_tree().create_timer(0.5), "timeout")
	
	$RetrieveRequest.request(operationLocation, 
	["Ocp-Apim-Subscription-Key: "+key],
	false, 
	HTTPClient.METHOD_GET)

func _on_RetrieveRequest_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	var json = JSON.parse(data)
	
	if !json.result.has("analyzeResult"):
		attemptRead()
		return
	
	print("--------------")
	print("succesful read "+str(response_code))
	print("--------------")
	var lines = json.result["analyzeResult"]["readResults"][0]["lines"]
	
	var text = ""
	for line in lines:
		print(line["text"])
		text += line["text"]
		text += " "
	
	scanning = false
	translateText(text)

func translateText(text):
	$TranslationRequest.request(translationURL, 
	["Content-Type: application/json",
	"Authorization: Token "+emotionToken],
	false, 
	HTTPClient.METHOD_POST, to_json(
		{"text" : text,
		"source" : "nld_Latn",
		"target" : "eng_Latn"}
		))

func _on_TranslationRequest_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	var json = JSON.parse(data)
	
	print("--------------")
	print("succesful translation "+str(response_code))
	print("--------------")
	print(json.result["translation_text"])
	
	yield(get_tree().create_timer(4.0), "timeout")
	
	readEmotions(json.result["translation_text"])

func readEmotions(text):
	$EmotionRequest.request(emotionURL, 
	["Content-Type: application/json",
	"Authorization: Token "+emotionToken],
	false, 
	HTTPClient.METHOD_POST, to_json({"text" : text}))

func _on_EmotionRequest_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	var json = JSON.parse(data)
	
	print("--------------")
	print("succesful emotion analysis "+str(response_code))
	print("--------------")
	
	var emotions = {}
	for emotionData in json.result["scored_labels"]:
		var emotionName = emotionData["label"]
		var score = emotionData["score"]
		
		TextDatabase.set(emotionName, TextDatabase.get(emotionName)+score)
		TextDatabase.emotionTotal += score
		emotions[emotionName] = score
	
	TextDatabase.addEmotion(emotions)
	TextDatabase.emit_signal("databaseChanged")
	
	scanning = false



