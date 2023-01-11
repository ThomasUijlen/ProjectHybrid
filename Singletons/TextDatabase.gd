extends Node

signal databaseChanged

var linesList = []
var emotionsList = []

var emotionTotal = 0.0
var sadness = 0.0
var joy = 0.0
var love = 0.0
var anger = 0.0
var fear = 0.0
var surprise = 0.0

func addText(lines):
	linesList.append(lines)

func addEmotion(emotions):
	emotionsList.append(emotions)

