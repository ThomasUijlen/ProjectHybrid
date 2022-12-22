extends Node2D

var key = "9026448ec0974609883be3a3fd84b2d2"
var endPoint = "https://legendarischeserver.cognitiveservices.azure.com/"
var host = "legendarischeserver.cognitiveservices.azure.com"
var imageURL = "https://learn.microsoft.com/nl-nl/azure/cognitive-services/computer-vision/images/handwritten-note.jpg"

var analyzeURL = "vision/v3.2/read/analyze"

var operationLocation = ""

func _ready():
#	$AnalyzeRequest.request(endPoint+analyzeURL, 
#	["Host: "+host,
#		"Content-Type: application/json",
#		"Ocp-Apim-Subscription-Key: "+key],
#	false, 
#	HTTPClient.METHOD_POST, to_json({"url" : imageURL}))
	
	var file = File.new()
	file.open("res://Images/Test2.jpg",File.READ)
	var fileContent = file.get_buffer(file.get_len())
	
	$AnalyzeRequest.request_raw(endPoint+analyzeURL, 
	["Host: "+host,
		"Content-Type: application/octet-stream",
		"Ocp-Apim-Subscription-Key: "+key],
	false, 
	HTTPClient.METHOD_POST, fileContent)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("request completed")
	print(response_code)
	print(headers[1])
	operationLocation = headers[1].split(": ")[1]
	print(operationLocation)
	
	attemptRead()

func attemptRead():
	yield(get_tree().create_timer(5), "timeout")
	
	$RetrieveRequest.request(operationLocation, 
	["Ocp-Apim-Subscription-Key: "+key],
	false, 
	HTTPClient.METHOD_GET)

func _on_RetrieveRequest_request_completed(result, response_code, headers, body):
	print("retrieve completed")
	var data = body.get_string_from_utf8()
	var json = JSON.parse(data)
	
	var lines = json.result["analyzeResult"]["readResults"][0]["lines"]
	for line in lines:
		print(line["text"])
