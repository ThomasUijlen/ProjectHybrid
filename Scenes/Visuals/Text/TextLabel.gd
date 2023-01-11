extends Node2D

func setText(lines):
	$Label.text = ""
	
	for i in range(lines):
		if i > 0: $Label.text += "\n"
		$Label.text += lines[i]

func setColor(color):
	pass
