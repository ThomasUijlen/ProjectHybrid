extends Node2D

func setText(lines):
	$Anchor/Label.text = ""
	
	for i in range(lines.size()):
		if i > 0: $Anchor/Label.text += "\n"
		$Anchor/Label.text += lines[i]

func setColor(c):
	$Anchor/Postit.modulate = Color.WHITE.lerp(c,0.5)
	$GPUParticles2D.modulate = c

func land():
	get_tree().current_scene.setPixelColor(position, $GPUParticles2D.modulate)
